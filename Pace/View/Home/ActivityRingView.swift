//
//  ActivityRingView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SwiftUI

struct ActivityRingView: View {
    var pedometerManager: PedometerManager

    private var stepsProgress: Double {
        Double(pedometerManager.steps) / 10000.0
    }

    private var distanceProgress: Double {
        pedometerManager.distance / 5000.0
    }

    private var caloriesProgress: Double {
        min(pedometerManager.currentCadence / 100.0, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ActivityRingWrapper(
                moveProgress: stepsProgress,
                exerciseProgress: distanceProgress,
                standProgress: caloriesProgress
            )
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 16) {
                StatRow(
                    icon: "figure.walk",
                    iconColor: .red,
                    value: pedometerManager.steps.formatted(),
                    label: "Steps"
                )

                StatRow(
                    icon: "location.fill",
                    iconColor: .green,
                    value: String(format: "%.1f km", pedometerManager.distance / 1000),
                    label: "Distance"
                )

                StatRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(Int(pedometerManager.currentCadence))",
                    label: "Cadence"
                )
            }
        }
        .padding()
    }
}

#Preview {
    ActivityRingView(pedometerManager: PedometerManager())
        .background(Color.black)
}
