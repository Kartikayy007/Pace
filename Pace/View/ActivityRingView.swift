//
//  ActivityRingView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SwiftUI

struct ActivityRingView: View {
    let stepsProgress: Double = 0.75
    let distanceProgress: Double = 0.45
    let caloriesProgress: Double = 0.90
    let steps: Int = 7500
    let distance: Double = 4.5
    let calories: Int = 320

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
                    value: steps.formatted(),
                    label: "Steps"
                )

                StatRow(
                    icon: "location.fill",
                    iconColor: .green,
                    value: String(format: "%.1f km", distance),
                    label: "Distance"
                )

                StatRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(calories)",
                    label: "Calories"
                )
            }
        }
        .padding()
    }
}

#Preview {
    ActivityRingView()
        .background(Color.white)
}
