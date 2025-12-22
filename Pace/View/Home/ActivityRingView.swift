//
//  ActivityRingView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SwiftUI

struct ActivityRingView: View {
    var viewModel: HomeViewModel
    private var settings = SettingsManager.shared
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    private var stepsProgress: Double {
        Double(viewModel.steps) / Double(settings.dailyStepsGoal)
    }

    private var distanceProgress: Double {
        viewModel.distance / settings.dailyDistanceGoal
    }

    private var caloriesProgress: Double {
        min(viewModel.calories / settings.dailyCaloriesGoal, 1.0)
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
                    value: viewModel.steps.formatted(),
                    label: "Steps"
                )

                StatRow(
                    icon: "location.fill",
                    iconColor: .green,
                    value: settings.formatDistance(viewModel.distance),
                    label: "Distance"
                )

                StatRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(Int(viewModel.calories))",
                    label: "Calories"
                )
            }
        }
        .padding()
    }
}

#Preview {
    ActivityRingView(viewModel: HomeViewModel())
        .background(Color.black)
}
