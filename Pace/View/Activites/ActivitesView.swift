//
//  ActivitesView.swift
//  Pace
//
//  Created by kartikay on 20/12/25.
//

import MapKit
import SwiftUI

struct ActivitesView: View {
    @State private var viewModel = ActivityViewModel()

    var body: some View {
        ZStack {
            ActivityMapBackground(cameraPosition: $viewModel.cameraPosition)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.currentActivityIcon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(viewModel.currentActivityColor)
                    Text(viewModel.selectedActivity)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                
                if viewModel.hasActiveGoals {
                    HStack(spacing: 16) {
                        if let distance = viewModel.distanceGoal {
                            GoalBadge(
                                icon: "point.topleft.down.to.point.bottomright.curvepath.fill",
                                value: String(format: "%.1f km", distance),
                                color: .blue
                            )
                        }
                        if let time = viewModel.timeGoal {
                            GoalBadge(
                                icon: "clock.fill",
                                value: "\(time) min",
                                color: .purple
                            )
                        }
                        if viewModel.countdownEnabled {
                            GoalBadge(
                                icon: "timer",
                                value: "\(viewModel.countdownSeconds)s",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                }

                Spacer()

                HStack(spacing: 24) {
                    Button(action: {
                        viewModel.showActivityPicker = true
                    }) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(viewModel.currentActivityColor)
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    }.glassEffect(.regular.interactive())

                    Button(action: {}) {
                        Text("Start")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                            .frame(width: 96, height: 96)
                            .background(
                                Circle()
                                    .fill(viewModel.currentActivityColor)
                                    .shadow(
                                        color: viewModel.currentActivityColor.opacity(0.5),
                                        radius: 20,
                                        y: 10
                                    )
                            )
                    }
                    
                    Button(action: {
                        viewModel.showSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    }.glassEffect(.regular.interactive())
                    
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
        .sheet(isPresented: $viewModel.showActivityPicker) {
            ActivityPickerSheet(
                activities: viewModel.activities,
                selectedActivity: $viewModel.selectedActivity,
                isPresented: $viewModel.showActivityPicker
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            ActivitySettingsSheet(
                countdownEnabled: $viewModel.countdownEnabled,
                countdownSeconds: $viewModel.countdownSeconds,
                distanceGoal: $viewModel.distanceGoal,
                timeGoal: $viewModel.timeGoal,
                isPresented: $viewModel.showSettingsSheet
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ActivitesView()
}

struct GoalBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive())
    }
}
