//
//  WorkoutService.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import Combine
import CoreLocation
import Foundation
import HealthKit

class WorkoutService: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var locationManager: CLLocationManager?
    private var routeLocations: [CLLocation] = []
    private var updateTimer: Timer?
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var calories: Double = 0
    @Published var heartRate: Double = 0
    @Published var pace: Double = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var lastWorkout: HKWorkout?
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws -> Bool {
        print("[WorkoutService] Requesting HealthKit authorization...")
        guard isHealthKitAvailable else {
            print("[WorkoutService] HealthKit not available on this device")
            return false
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        print("[WorkoutService] HealthKit authorization granted")
        return true
    }
    
    func prepare(activityType: HKWorkoutActivityType, isIndoor: Bool) {
        print("[WorkoutService] Preparing workout session...")
        print("[WorkoutService] Activity type: \(activityType.rawValue), Indoor: \(isIndoor)")
        
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = isIndoor ? .indoor : .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            
            session?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )
            
            if !isIndoor {
                routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
                setupLocationManager()
                print("[WorkoutService] Route builder initialized for outdoor workout")
            }
            
            session?.prepare()
            print("[WorkoutService] Session prepared - sensors warming up")
        } catch {
            print("[WorkoutService] ERROR: Failed to create workout session: \(error)")
        }
    }
    
    private func setupLocationManager() {
        print("[WorkoutService] Setting up location manager...")
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = kCLDistanceFilterNone 
        locationManager?.activityType = .fitness
        locationManager?.allowsBackgroundLocationUpdates = true 
        locationManager?.pausesLocationUpdatesAutomatically = false 
        locationManager?.requestWhenInUseAuthorization()
        print("[WorkoutService] Location manager configured for workout tracking")
    }
    
    func start() {
        print("[WorkoutService] Starting workout...")
        guard let session = session, let builder = builder else {
            print("[WorkoutService] ERROR: Session or builder is nil")
            return
        }
        
        let startDate = Date()
        print("[WorkoutService] Start time: \(startDate)")
        
        session.startActivity(with: startDate)
        print("[WorkoutService] Session activity started")
        
        builder.beginCollection(withStart: startDate) { [weak self] success, error in
            if success {
                print("[WorkoutService] Data collection started successfully")
                DispatchQueue.main.async {
                    self?.isActive = true
                    self?.isPaused = false
                    self?.startUpdateTimer()
                }
                self?.locationManager?.startUpdatingLocation()
            } else if let error = error {
                print("[WorkoutService] ERROR: Failed to begin collection: \(error)")
            }
        }
    }
    
    private func startUpdateTimer() {
        print("[WorkoutService] Starting update timer...")
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    private func stopUpdateTimer() {
        print("[WorkoutService] Stopping update timer...")
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func pause() {
        print("[WorkoutService] Pausing workout...")
        session?.pause()
        locationManager?.stopUpdatingLocation()
        stopUpdateTimer()
    }
    
    func resume() {
        print("[WorkoutService] Resuming workout...")
        session?.resume()
        locationManager?.startUpdatingLocation()
        startUpdateTimer()
    }
    
    func stop() async -> HKWorkout? {
        print("[WorkoutService] Stopping workout...")
        guard let session = session, let builder = builder else {
            print("[WorkoutService] ERROR: Session or builder is nil")
            return nil
        }
        
        let endDate = Date()
        print("[WorkoutService] End time: \(endDate)")
        
        stopUpdateTimer()
        locationManager?.stopUpdatingLocation()
        
        session.stopActivity(with: endDate)
        print("[WorkoutService] Session activity stopped")
        
        await withCheckedContinuation { continuation in
            builder.endCollection(withEnd: endDate) { success, error in
                if success {
                    print("[WorkoutService] Data collection ended successfully")
                } else if let error = error {
                    print("[WorkoutService] ERROR: Failed to end collection: \(error)")
                }
                continuation.resume()
            }
        }
        
        session.end()
        print("[WorkoutService] Session ended")
        
        do {
            guard let workout = try await builder.finishWorkout() else {
                print("[WorkoutService] ERROR: Workout is nil after finishing")
                reset()
                return nil
            }
            
            print("[WorkoutService] Workout saved to HealthKit!")
            print("[WorkoutService] Duration: \(workout.duration) seconds")
            print("[WorkoutService] Total energy: \(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) kcal")
            print("[WorkoutService] Total distance: \(workout.totalDistance?.doubleValue(for: .meter()) ?? 0) meters")
            
            if routeBuilder != nil, !routeLocations.isEmpty {
                print("[WorkoutService] Saving route with \(routeLocations.count) locations...")
                try await saveRoute(for: workout)
            }
            
            DispatchQueue.main.async {
                self.lastWorkout = workout
                self.isActive = false
                self.isPaused = false
            }
            
            let finalWorkout = workout
            reset()
            return finalWorkout
        } catch {
            print("[WorkoutService] ERROR: Failed to finish workout: \(error)")
            reset()
            return nil
        }
    }
    
    private func saveRoute(for workout: HKWorkout) async throws {
        guard let routeBuilder = routeBuilder else { return }
        
        
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            routeBuilder.finishRoute(with: workout, metadata: nil) { route, error in
                if let error = error {
                    print("[WorkoutService] ERROR: Failed to save route: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("[WorkoutService] Route saved successfully with \(self.routeLocations.count) points")
                    continuation.resume()
                }
            }
        }
    }
    
    private func reset() {
        print("[WorkoutService] Resetting service state")
        stopUpdateTimer()
        elapsedTime = 0
        distance = 0
        calories = 0
        heartRate = 0
        pace = 0
        session = nil
        builder = nil
        routeBuilder = nil
        routeLocations = []
        locationManager = nil
    }
    
    private func updateMetrics() {
        guard let builder = builder else { return }
        
        let statistics = builder.allStatistics
        
        if let distanceStat = statistics[HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!] {
            let distanceValue = distanceStat.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            DispatchQueue.main.async {
                self.distance = distanceValue / 1000.0
            }
        }
        
        if let caloriesStat = statistics[HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!] {
            let caloriesValue = caloriesStat.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            DispatchQueue.main.async {
                self.calories = caloriesValue
            }
        }
        
        if let heartRateStat = statistics[HKQuantityType.quantityType(forIdentifier: .heartRate)!] {
            let hrValue = heartRateStat.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
            DispatchQueue.main.async {
                self.heartRate = hrValue
            }
        }
        
        DispatchQueue.main.async {
            self.elapsedTime = self.builder?.elapsedTime ?? 0
            if self.distance > 0 && self.elapsedTime > 0 {
                self.pace = self.elapsedTime / self.distance
            }
        }
    }
    
    func fetchRecentWorkouts(limit: Int = 10) async -> [HKWorkout] {
        print("[WorkoutService] Fetching recent workouts...")
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("[WorkoutService] ERROR: Failed to fetch workouts: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                print("[WorkoutService] Fetched \(workouts.count) workouts")
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchRoute(for workout: HKWorkout) async -> [CLLocation] {
        print("[WorkoutService] Fetching route for workout...")
        
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let routes: [HKWorkoutRoute] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("[WorkoutService] ERROR: Failed to fetch route: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                let routes = samples as? [HKWorkoutRoute] ?? []
                continuation.resume(returning: routes)
            }
            
            healthStore.execute(query)
        }
        
        guard let route = routes.first else {
            print("[WorkoutService] No route found for workout")
            return []
        }
        
        var locations: [CLLocation] = []
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKWorkoutRouteQuery(route: route) { _, newLocations, done, error in
                if let error = error {
                    print("[WorkoutService] ERROR: Failed to query route locations: \(error)")
                }
                
                if let newLocations = newLocations {
                    locations.append(contentsOf: newLocations)
                }
                
                if done {
                    print("[WorkoutService] Fetched \(locations.count) route locations")
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
        
        return locations
    }
    
    
    
    func fetchHeartRateData(for workout: HKWorkout) async -> [HeartRateSample] {
        print("[WorkoutService] Fetching heart rate data...")
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("[WorkoutService] ERROR: Failed to fetch heart rate: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                let hrSamples = (samples as? [HKQuantitySample])?.map { sample in
                    HeartRateSample(
                        date: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    )
                } ?? []
                
                print("[WorkoutService] Fetched \(hrSamples.count) heart rate samples")
                continuation.resume(returning: hrSamples)
            }
            
            healthStore.execute(query)
        }
    }
}

extension WorkoutService: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("[WorkoutService] Session state changed: \(fromState.rawValue) -> \(toState.rawValue)")
        
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.isActive = true
                self.isPaused = false
            case .paused:
                self.isPaused = true
            case .stopped, .ended:
                self.isActive = false
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[WorkoutService] ERROR: Workout session failed: \(error)")
    }
}

extension WorkoutService: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        updateMetrics()
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("[WorkoutService] Workout event collected")
    }
}

extension WorkoutService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let filteredLocations = locations.filter { $0.horizontalAccuracy < 50 && $0.horizontalAccuracy > 0 }
        
        guard !filteredLocations.isEmpty else { return }
        
        
        routeLocations.append(contentsOf: filteredLocations)
        
        
        
        routeBuilder?.insertRouteData(filteredLocations) { success, error in
            if let error = error {
                print("[WorkoutService] ERROR: Failed to insert route data: \(error)")
            }
        }
        
        print("[WorkoutService] Added \(filteredLocations.count) GPS locations (total: \(routeLocations.count))")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[WorkoutService] ERROR: Location manager failed: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("[WorkoutService] Location authorization status changed: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("[WorkoutService] Location access granted")
        case .denied, .restricted:
            print("[WorkoutService] ERROR: Location access denied")
        case .notDetermined:
            print("[WorkoutService] Location access not determined yet")
        @unknown default:
            break
        }
    }
}
