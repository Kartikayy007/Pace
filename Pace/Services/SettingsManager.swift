//
//  SettingsManager.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import Foundation
import SwiftUI

@Observable
class SettingsManager {
    static let shared = SettingsManager()
    
    private let userDefaultsKey = "app_settings"
    
    private(set) var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    var unitSystem: UnitSystem {
        get { settings.unitSystem }
        set { settings.unitSystem = newValue }
    }
    
    var appearanceMode: AppearanceMode {
        get { settings.appearanceMode }
        set { settings.appearanceMode = newValue }
    }
    
    var goals: Goals {
        get { settings.goals }
        set { settings.goals = newValue }
    }
    
    var dailyStepsGoal: Int {
        get { settings.goals.dailySteps }
        set { settings.goals.dailySteps = newValue }
    }
    
    var dailyDistanceGoal: Double {
        get { settings.goals.dailyDistance }
        set { settings.goals.dailyDistance = newValue }
    }
    
    var dailyCaloriesGoal: Double {
        get { settings.goals.dailyCalories }
        set { settings.goals.dailyCalories = newValue }
    }
    
    private init() {
        self.settings = SettingsManager.loadSettings()
    }
    
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "app_settings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func resetToDefaults() {
        settings = .default
    }
    
    func formatDistance(_ meters: Double) -> String {
        return unitSystem.formatDistanceString(meters)
    }
    
    func formatDistanceValue(_ meters: Double) -> Double {
        return unitSystem.formatDistance(meters)
    }
    
    func distanceToMeters(_ value: Double) -> Double {
        return unitSystem.toMeters(value)
    }
    
    var distanceUnit: String {
        return unitSystem.distanceUnit
    }
}
