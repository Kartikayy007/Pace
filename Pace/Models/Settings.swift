//
//  Settings.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import Foundation
import SwiftUI

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var distanceUnit: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "mi"
        }
    }
    
    var distanceUnitFull: String {
        switch self {
        case .metric: return "kilometers"
        case .imperial: return "miles"
        }
    }
    
    func formatDistance(_ meters: Double) -> Double {
        switch self {
        case .metric: return meters / 1000.0
        case .imperial: return meters / 1609.34
        }
    }
    
    func toMeters(_ value: Double) -> Double {
        switch self {
        case .metric: return value * 1000.0
        case .imperial: return value * 1609.34
        }
    }
    
    func formatDistanceString(_ meters: Double) -> String {
        let value = formatDistance(meters)
        return String(format: "%.1f %@", value, distanceUnit)
    }
}

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct Goals: Codable, Equatable {
    var dailySteps: Int
    var dailyDistance: Double
    var dailyCalories: Double
    
    static let `default` = Goals(
        dailySteps: 10000,
        dailyDistance: 5000,
        dailyCalories: 500
    )
}

struct AppSettings: Codable, Equatable {
    var unitSystem: UnitSystem
    var appearanceMode: AppearanceMode
    var goals: Goals
    
    static let `default` = AppSettings(
        unitSystem: .metric,
        appearanceMode: .system,
        goals: .default
    )
}
