//
//  ActivityViewModel.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

enum ActivitySessionState: Equatable {
    case idle
    case countdown(Int)
    case active
    case paused

    var isSessionActive: Bool {
        switch self {
        case .idle:
            return false
        case .countdown, .active, .paused:
            return true
        }
    }
}

@Observable
class ActivityViewModel {
    private let locationService = LocationService()
    private let workoutService = WorkoutService()
    private let announcementService = AnnouncementService.shared
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?

    var isAnnouncementsMuted: Bool = false {
        didSet {
            announcementService.isMuted = isAnnouncementsMuted
        }
    }

    var selectedActivity: Activity = .walk
    var showActivityPicker: Bool = false
    var showSettingsSheet: Bool = false
    var cameraPosition: MapCameraPosition = .automatic

    var sessionState: ActivitySessionState = .idle

    var countdownEnabled: Bool = false
    var countdownSeconds: Int = 3
    var distanceGoal: Double? = nil
    var timeGoal: Int? = nil

    var elapsedTime: TimeInterval = 0
    var currentDistance: Double = 0
    var currentCalories: Double = 0
    var currentHeartRate: Double = 0
    var currentPace: Double = 0
    var currentCadence: Double = 0
    var liveRoute: [CLLocation] = []

    let activities: [Activity] = Activity.all

    var currentActivityIcon: String {
        selectedActivity.icon
    }

    var currentActivityColor: Color {
        selectedActivity.color
    }

    var currentGoal: ActivityGoal {
        selectedActivity.defaultGoal
    }

    var ringProgress: Double {

        let goalMinutes = Double(timeGoal ?? currentGoal.timeMinutes)
        let goalDistanceKm = distanceGoal ?? currentGoal.distanceKm
        let goalCaloriesKcal = Double(currentGoal.caloriesKcal)

        let elapsedMinutes = elapsedTime / 60.0
        let timeProgress = min(elapsedMinutes / goalMinutes, 1.0)

        let distanceProgress = goalDistanceKm > 0 ? min(currentDistance / goalDistanceKm, 1.0) : 0

        let caloriesProgress =
            goalCaloriesKcal > 0 ? min(currentCalories / goalCaloriesKcal, 1.0) : 0

        let overallProgress =
            (timeProgress * 0.4) + (distanceProgress * 0.4) + (caloriesProgress * 0.2)
        return min(overallProgress, 1.0)
    }

    var hasActiveGoals: Bool {
        distanceGoal != nil || timeGoal != nil || countdownEnabled
    }

    init() {
        setupLocationBinding()
        setupWorkoutBinding()
    }

    func requestAuthorization() async {
        do {
            _ = try await workoutService.requestAuthorization()
        } catch {
            print("[ActivityViewModel] HealthKit authorization failed: \(error)")
        }
    }

    func requestLocationPermission() {
        locationService.requestPermission()
    }

    private func setupLocationBinding() {
        locationService.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateCameraPosition(to: location)
            }
            .store(in: &cancellables)
    }

    private func setupWorkoutBinding() {
        workoutService.$elapsedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                self.elapsedTime = value

                // Check time goal
                if let goalMinutes = self.timeGoal {
                    self.announcementService.checkTimeGoal(
                        elapsedMinutes: value / 60.0,
                        goalMinutes: goalMinutes
                    )
                }
            }
            .store(in: &cancellables)

        workoutService.$distance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                self.currentDistance = value

                // Check km milestone announcements
                self.announcementService.checkKilometerMilestone(
                    distanceKm: value,
                    paceSecondsPerKm: self.currentPace
                )

                // Check distance goal
                if let goalKm = self.distanceGoal {
                    self.announcementService.checkDistanceGoal(currentKm: value, goalKm: goalKm)
                }
            }
            .store(in: &cancellables)

        workoutService.$calories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentCalories = value
            }
            .store(in: &cancellables)

        workoutService.$heartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentHeartRate = value
            }
            .store(in: &cancellables)

        workoutService.$pace
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentPace = value
            }
            .store(in: &cancellables)

        workoutService.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isActive: Bool) in
                print("[ActivityViewModel] isActive changed: \(isActive)")
                if isActive && self?.sessionState != .active && self?.sessionState != .paused {
                    self?.sessionState = .active
                }
            }
            .store(in: &cancellables)

        workoutService.$isPaused
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isPaused: Bool) in
                print("[ActivityViewModel] isPaused changed: \(isPaused)")
                if isPaused {
                    self?.sessionState = .paused
                } else if self?.workoutService.isActive == true {
                    self?.sessionState = .active
                }
            }
            .store(in: &cancellables)

        workoutService.$liveRoute
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.liveRoute = value
            }
            .store(in: &cancellables)

        workoutService.$cadence
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentCadence = value
            }
            .store(in: &cancellables)
    }

    private func updateCameraPosition(to location: CLLocation) {
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: location.coordinate,
                distance: 800
            ))
    }

    func startSession() {
        workoutService.prepare(
            activityType: selectedActivity.workoutType,
            isIndoor: selectedActivity.isIndoor
        )

        let startValue = countdownEnabled ? countdownSeconds : 3
        sessionState = .countdown(startValue)
        startCountdown(from: startValue)
    }

    func pauseSession() {
        workoutService.pause()
    }

    func resumeSession() {
        workoutService.resume()
    }

    func endSession() {
        countdownTimer?.invalidate()
        countdownTimer = nil

        Task {
            _ = await workoutService.stop()
            await MainActor.run {
                sessionState = .idle
            }
        }
    }

    private func startCountdown(from value: Int) {
        var remaining = value
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] timer in
            remaining -= 1
            if remaining > 0 {
                self?.sessionState = .countdown(remaining)
            } else {
                timer.invalidate()
                self?.countdownTimer = nil
                self?.announcementService.reset()
                self?.announcementService.announceWorkoutStart()
                self?.workoutService.start()
                self?.sessionState = .active
            }
        }
    }
}
