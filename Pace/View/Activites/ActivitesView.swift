//
//  ActivitesView.swift
//  Pace
//
//  Created by kartikay on 20/12/25.
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }
}

struct ActivitesView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showActivityPicker = false
    @State private var selectedActivity = "Walk"
    @State private var cameraPosition: MapCameraPosition = .automatic

    let activities = [
        Activity(title: "Walk", icon: "figure.walk", color: .green),
        Activity(title: "Run", icon: "figure.run", color: .orange),
        Activity(title: "Hike", icon: "figure.hiking", color: .brown),
        Activity(title: "Treadmill", icon: "figure.run.treadmill", color: .cyan),
    ]

    var body: some View {
        ZStack {
            
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            .overlay(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.7),
                        .clear,
                        .clear,
                        Color(.systemBackground).opacity(0.5),
                        Color(.systemBackground),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )


            VStack {
                
                HStack(spacing: 12) {
                    Image(systemName: currentActivityIcon)
                        .font(.system(size: 24))
                        .foregroundColor(currentActivityColor)
                    Text(selectedActivity)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                Spacer()

                
                VStack(spacing: 20) {
                    
                    Button(action: {
                        
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Start \(selectedActivity)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            Capsule()
                                .fill(currentActivityColor)
                                .shadow(color: currentActivityColor.opacity(0.4), radius: 15, y: 8)
                        )
                    }
                    .padding(.horizontal, 40)
             
                    HStack(spacing: 16) {
                        OptionButton(icon: "gearshape.fill", label: "Settings")
                        OptionButton(icon: "target", label: "Goal")
                        OptionButton(icon: "music.note", label: "Music")
                    }
                    .padding(.horizontal, 24)
      
                    Button(action: {
                        showActivityPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: currentActivityIcon)
                            Text(selectedActivity)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Image(systemName: "chevron.up.circle.fill")
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive())
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            if let location = locationManager.location {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: 800
                    ))
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                withAnimation {
                    cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 800
                        ))
                }
            }
        }
        .sheet(isPresented: $showActivityPicker) {
            ActivityPickerSheet(
                activities: activities,
                selectedActivity: $selectedActivity,
                isPresented: $showActivityPicker
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    var currentActivityIcon: String {
        activities.first { $0.title == selectedActivity }?.icon ?? "figure.walk"
    }

    var currentActivityColor: Color {
        activities.first { $0.title == selectedActivity }?.color ?? .green
    }
}

struct OptionButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive())
    }
}

struct ActivityPickerSheet: View {
    let activities: [Activity]
    @Binding var selectedActivity: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List(activities) { activity in
                Button(action: {
                    selectedActivity = activity.title
                    isPresented = false
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: activity.icon)
                            .font(.system(size: 28))
                            .foregroundColor(activity.color)
                            .frame(width: 50)

                        Text(activity.title)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedActivity == activity.title {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Choose Activity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ActivitesView()
}
