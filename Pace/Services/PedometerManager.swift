//
//  PedometerManager.swift
//  Pace
//
//  Created by kartikay on 20/12/25.
//

import CoreMotion
import Foundation

@Observable
class PedometerManager {
    private let pedometer = CMPedometer()

    var currentPace: Double = 0
    var currentCadence: Double = 0
    var steps: Int = 0
    var distance: Double = 0

    var hourlySteps: [StepDataPoint] = []

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    init() {
        for hour in 0..<24 {
            hourlySteps.append(StepDataPoint(hour: hour, steps: 0))
        }
    }

    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else {
            print("Pedometer not available")
            return
        }

        loadHourlyStepData()

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        pedometer.queryPedometerData(from: startOfDay, to: now) { [weak self] data, error in
            DispatchQueue.main.async {
                if let data = data {
                    self?.steps = data.numberOfSteps.intValue
                    self?.distance = data.distance?.doubleValue ?? 0
                }
            }
        }

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let data = data else { return }

                if let pace = data.currentPace?.doubleValue {
                    self?.currentPace = pace / 60
                }

                if let cadence = data.currentCadence?.doubleValue {
                    self?.currentCadence = cadence * 60
                }

                self?.refreshTodayTotals()
            }
        }
    }

    private func refreshTodayTotals() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        pedometer.queryPedometerData(from: startOfDay, to: now) { [weak self] data, error in
            DispatchQueue.main.async {
                if let data = data {
                    self?.steps = data.numberOfSteps.intValue
                    self?.distance = data.distance?.doubleValue ?? 0
                }
            }
        }
    }

    private func loadHourlyStepData() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let currentHour = calendar.component(.hour, from: now)

        for hour in 0...currentHour {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: startOfDay)
            else {
                continue
            }

            let queryEnd = min(hourEnd, now)

            pedometer.queryPedometerData(from: hourStart, to: queryEnd) { [weak self] data, error in
                DispatchQueue.main.async {
                    let stepCount = data?.numberOfSteps.intValue ?? 0

                    if let index = self?.hourlySteps.firstIndex(where: { $0.hour == hour }) {
                        self?.hourlySteps[index] = StepDataPoint(hour: hour, steps: stepCount)
                    }
                }
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
    }
}

struct StepDataPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let steps: Int

    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H"
        let date =
            Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
