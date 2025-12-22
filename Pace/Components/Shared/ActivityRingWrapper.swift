//
//  ActivityRingWrapper.swift
//  Pace
//
//  Created by kartikay on 20/12/25.
//

import HealthKit
import HealthKitUI
import SwiftUI

struct ActivityRingWrapper: UIViewRepresentable {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double

    func makeUIView(context: Context) -> HKActivityRingView {
        let ringView = HKActivityRingView()
        ringView.setActivitySummary(createSummary(), animated: false)
        return ringView
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.setActivitySummary(createSummary(), animated: true)
    }

    private func createSummary() -> HKActivitySummary {
        let summary = HKActivitySummary()

        summary.activeEnergyBurned = HKQuantity(
            unit: .kilocalorie(), doubleValue: moveProgress * 100)
        summary.activeEnergyBurnedGoal = HKQuantity(unit: .kilocalorie(), doubleValue: 100)

        summary.appleExerciseTime = HKQuantity(unit: .minute(), doubleValue: exerciseProgress * 100)
        summary.appleExerciseTimeGoal = HKQuantity(unit: .minute(), doubleValue: 100)

        summary.appleStandHours = HKQuantity(unit: .count(), doubleValue: standProgress * 12)
        summary.appleStandHoursGoal = HKQuantity(unit: .count(), doubleValue: 12)

        return summary
    }
}

#Preview {
    ActivityRingWrapper(
        moveProgress: 0.75,
        exerciseProgress: 0.45,
        standProgress: 0.90
    )
    .frame(width: 150, height: 150)
}
