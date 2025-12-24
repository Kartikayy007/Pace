//
//  ActivitySettingsSheet.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import SwiftUI

struct ActivitySettingsSheet: View {
    @Binding var countdownEnabled: Bool
    @Binding var countdownSeconds: Int
    @Binding var distanceGoal: Double?
    @Binding var timeGoal: Int?
    @Binding var isPresented: Bool

    @AppStorage("activityDistanceGoal") private var savedDistanceGoal: Double = 5.0
    @AppStorage("activityTimeGoal") private var savedTimeGoal: Int = 30
    @AppStorage("activityCountdownEnabled") private var savedCountdownEnabled: Bool = true
    @AppStorage("activityCountdownSeconds") private var savedCountdownSeconds: Int = 3

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $countdownEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            Text("Countdown")
                        }
                    }
                    .onChange(of: countdownEnabled) { _, newValue in
                        savedCountdownEnabled = newValue
                    }

                    if countdownEnabled {
                        Picker("Seconds", selection: $countdownSeconds) {
                            Text("3s").tag(3)
                            Text("5s").tag(5)
                            Text("10s").tag(10)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: countdownSeconds) { _, newValue in
                            savedCountdownSeconds = newValue
                        }
                    }
                } header: {
                    Text("Start Options")
                }

                Section {
                    HStack {
                        HStack(spacing: 12) {
                            Image(
                                systemName: "point.topleft.down.to.point.bottomright.curvepath.fill"
                            )
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 28)
                            Text("Distance")
                        }
                        Spacer()
                        Stepper(
                            value: Binding(
                                get: { distanceGoal ?? savedDistanceGoal },
                                set: { newValue in
                                    distanceGoal = newValue
                                    savedDistanceGoal = newValue
                                }
                            ), in: 0.5...100, step: 0.5
                        ) {
                            Text(String(format: "%.1f km", distanceGoal ?? savedDistanceGoal))
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                        }
                    }

                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                                .frame(width: 28)
                            Text("Time")
                        }
                        Spacer()
                        Stepper(
                            value: Binding(
                                get: { timeGoal ?? savedTimeGoal },
                                set: { newValue in
                                    timeGoal = newValue
                                    savedTimeGoal = newValue
                                }
                            ), in: 5...180, step: 5
                        ) {
                            Text("\(timeGoal ?? savedTimeGoal) min")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Goals are used to calculate your overall progress ring.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                countdownEnabled = savedCountdownEnabled
                countdownSeconds = savedCountdownSeconds
                if distanceGoal == nil {
                    distanceGoal = savedDistanceGoal
                }
                if timeGoal == nil {
                    timeGoal = savedTimeGoal
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
