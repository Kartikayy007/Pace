//
//  PedometerService.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import CoreMotion
import Foundation
import HealthKit

class PedometerService {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    private var healthKitAuthorized = false

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        guard isHealthKitAvailable else {
            completion(false)
            return
        }
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let typesToRead: Set<HKObjectType> = [calorieType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.healthKitAuthorized = success
                completion(success)
            }
        }
    }
    
    func queryTodayCalories(completion: @escaping (Double) -> Void) {
        if healthKitAuthorized && isHealthKitAvailable {
            queryHealthKitCalories(completion: completion)
        } else {
            completion(0)
        }
    }
    
    private func queryHealthKitCalories(completion: @escaping (Double) -> Void) {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                let calories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                completion(calories)
            }
        }
        
        healthStore.execute(query)
    }
    
    static func calculateCalories(fromSteps steps: Int, distance: Double) -> Double {
        if distance > 0 {
            return (distance / 1000.0) * 60.0
        } else {
            return Double(steps) * 0.04
        }
    }

    func queryTodayData(completion: @escaping (Int, Double) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        pedometer.queryPedometerData(from: startOfDay, to: now) { data, error in
            DispatchQueue.main.async {
                let steps = data?.numberOfSteps.intValue ?? 0
                let distance = data?.distance?.doubleValue ?? 0
                completion(steps, distance)
            }
        }
    }

    func queryHourlyData(completion: @escaping ([StepDataPoint]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let currentHour = calendar.component(.hour, from: now)

        var results: [StepDataPoint] = (0..<24).map { StepDataPoint(hour: $0, steps: 0) }
        let group = DispatchGroup()

        for hour in 0...currentHour {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: startOfDay)
            else { continue }

            let queryEnd = min(hourEnd, now)
            group.enter()

            pedometer.queryPedometerData(from: hourStart, to: queryEnd) { data, error in
                let stepCount = data?.numberOfSteps.intValue ?? 0
                results[hour] = StepDataPoint(hour: hour, steps: stepCount)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    func startLiveUpdates(onUpdate: @escaping (Double, Double) -> Void) {
        pedometer.startUpdates(from: Date()) { data, error in
            DispatchQueue.main.async {
                guard let data = data else { return }
                let pace = data.currentPace?.doubleValue ?? 0
                let cadence = (data.currentCadence?.doubleValue ?? 0) * 60
                onUpdate(pace / 60, cadence)
            }
        }
    }

    func stopUpdates() {
        pedometer.stopUpdates()
    }
}
