//
//  Activity.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import HealthKit
import SwiftUI

struct ActivityGoal {
    let timeMinutes: Int
    let distanceKm: Double
    let caloriesKcal: Int
    
    static let walk = ActivityGoal(timeMinutes: 30, distanceKm: 2.0, caloriesKcal: 150)
    static let run = ActivityGoal(timeMinutes: 20, distanceKm: 3.0, caloriesKcal: 250)
    static let hike = ActivityGoal(timeMinutes: 60, distanceKm: 5.0, caloriesKcal: 400)
    static let treadmill = ActivityGoal(timeMinutes: 25, distanceKm: 2.5, caloriesKcal: 200)
}

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let defaultGoal: ActivityGoal
    let workoutType: HKWorkoutActivityType
    let isIndoor: Bool
    
    static let walk = Activity(
        title: "Walk",
        icon: "figure.walk",
        color: .green,
        defaultGoal: .walk,
        workoutType: .walking,
        isIndoor: false
    )
    
    static let run = Activity(
        title: "Run",
        icon: "figure.run",
        color: .orange,
        defaultGoal: .run,
        workoutType: .running,
        isIndoor: false
    )
    
    static let hike = Activity(
        title: "Hike",
        icon: "figure.hiking",
        color: .brown,
        defaultGoal: .hike,
        workoutType: .hiking,
        isIndoor: false
    )
    
    static let treadmill = Activity(
        title: "Treadmill",
        icon: "figure.run.treadmill",
        color: .cyan,
        defaultGoal: .treadmill,
        workoutType: .walking,
        isIndoor: true
    )
    
    static let all: [Activity] = [.walk, .run, .hike, .treadmill]
}
