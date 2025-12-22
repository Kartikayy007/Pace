//
//  HomeViewModel.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import Foundation

@Observable
class HomeViewModel {
    private let pedometerService = PedometerService()

    var steps: Int = 0
    var distance: Double = 0
    var currentPace: Double = 0
    var currentCadence: Double = 0
    var calories: Double = 0
    var hourlySteps: [StepDataPoint] = []

    var isAvailable: Bool {
        pedometerService.isAvailable
    }

    init() {
        for hour in 0..<24 {
            hourlySteps.append(StepDataPoint(hour: hour, steps: 0))
        }
    }

    func startTracking() {
        guard pedometerService.isAvailable else {
            print("Pedometer not available")
            return
        }

        pedometerService.requestHealthKitAuthorization { [weak self] authorized in
            self?.loadCalories()
        }
        
        loadHourlyData()
        loadTodayTotals()
        startLiveUpdates()
    }

    func stopTracking() {
        pedometerService.stopUpdates()
    }

    private func loadTodayTotals() {
        pedometerService.queryTodayData { [weak self] steps, distance in
            self?.steps = steps
            self?.distance = distance
            if self?.calories == 0 {
                self?.calories = PedometerService.calculateCalories(fromSteps: steps, distance: distance)
            }
        }
    }
    
    private func loadCalories() {
        pedometerService.queryTodayCalories { [weak self] healthKitCalories in
            if healthKitCalories > 0 {
                self?.calories = healthKitCalories
            } else {
                if let steps = self?.steps, let distance = self?.distance {
                    self?.calories = PedometerService.calculateCalories(fromSteps: steps, distance: distance)
                }
            }
        }
    }

    private func loadHourlyData() {
        pedometerService.queryHourlyData { [weak self] data in
            self?.hourlySteps = data
        }
    }

    private func startLiveUpdates() {
        pedometerService.startLiveUpdates { [weak self] pace, cadence in
            self?.currentPace = pace
            self?.currentCadence = cadence
            self?.loadTodayTotals()
            self?.loadCalories()
        }
    }
}
