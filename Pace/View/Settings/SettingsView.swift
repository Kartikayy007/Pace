//
//  SettingsView.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import SwiftUI

struct SettingsView: View {
    private var settings = SettingsManager.shared
    
    @State private var stepGoal: Double = 10000
    @State private var distanceGoal: Double = 5.0
    @State private var calorieGoal: Double = 500
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Daily Steps Goal")
                            Spacer()
                            Text("\(Int(stepGoal))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $stepGoal, in: 1000...30000, step: 500)
                            .tint(.red)
                            .onChange(of: stepGoal) { _, newValue in
                                settings.dailyStepsGoal = Int(newValue)
                            }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("Daily Distance Goal")
                            Spacer()
                            Text(String(format: "%.1f %@", distanceGoal, settings.distanceUnit))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $distanceGoal, in: 1...50, step: 0.5)
                            .tint(.green)
                            .onChange(of: distanceGoal) { _, newValue in
                                settings.dailyDistanceGoal = settings.distanceToMeters(newValue)
                            }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Daily Calories Goal")
                            Spacer()
                            Text("\(Int(calorieGoal)) kcal")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $calorieGoal, in: 100...2000, step: 50)
                            .tint(.orange)
                            .onChange(of: calorieGoal) { _, newValue in
                                settings.dailyCaloriesGoal = newValue
                            }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Set your daily activity goals. The rings on the home screen show your progress toward these goals.")
                }
                
                Section {
                    Picker(selection: Binding(
                        get: { settings.unitSystem },
                        set: { settings.unitSystem = $0 }
                    )) {
                        ForEach(UnitSystem.allCases, id: \.self) { unit in
                            Text(unit == .metric ? "Metric (km)" : "Imperial (mi)")
                                .tag(unit)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Distance Unit")
                        }
                    }
                } header: {
                    Text("Units")
                }
                
                Section {
                    Picker(selection: Binding(
                        get: { settings.appearanceMode },
                        set: { settings.appearanceMode = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Appearance")
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose how the app looks. System will follow your device settings.")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        settings.resetToDefaults()
                        loadCurrentSettings()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Reset to Defaults")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    private func loadCurrentSettings() {
        stepGoal = Double(settings.dailyStepsGoal)
        distanceGoal = settings.formatDistanceValue(settings.dailyDistanceGoal)
        calorieGoal = settings.dailyCaloriesGoal
    }
}

#Preview {
    SettingsView()
}
