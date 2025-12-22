//
//  ActivityViewModel.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

@Observable
class ActivityViewModel {
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()

    var selectedActivity: String = "Walk"
    var showActivityPicker: Bool = false
    var showSettingsSheet: Bool = false
    var cameraPosition: MapCameraPosition = .automatic
    
    var countdownEnabled: Bool = false
    var countdownSeconds: Int = 3
    var distanceGoal: Double? = nil
    var timeGoal: Int? = nil

    let activities = [
        Activity(title: "Walk", icon: "figure.walk", color: .green),
        Activity(title: "Run", icon: "figure.run", color: .orange),
        Activity(title: "Hike", icon: "figure.hiking", color: .brown),
        Activity(title: "Treadmill", icon: "figure.run.treadmill", color: .cyan),
    ]

    var currentActivityIcon: String {
        activities.first { $0.title == selectedActivity }?.icon ?? "figure.walk"
    }

    var currentActivityColor: Color {
        activities.first { $0.title == selectedActivity }?.color ?? .green
    }
    
    var hasActiveGoals: Bool {
        distanceGoal != nil || timeGoal != nil || countdownEnabled
    }

    init() {
        setupLocationBinding()
    }

    func requestLocationPermission() {
        locationService.requestPermission()
    }

    private func setupLocationBinding() {
        locationService.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateCameraPosition(to: location)
            }
            .store(in: &cancellables)
    }

    private func updateCameraPosition(to location: CLLocation) {
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: location.coordinate,
                distance: 800
            ))
    }
}

