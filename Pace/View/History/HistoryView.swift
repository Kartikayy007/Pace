//
//  HistoryView.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import Charts
import CoreLocation
import HealthKit
import MapKit
import SwiftUI

struct HistoryView: View {
    @State private var workouts: [HKWorkout] = []
    @State private var isLoading = true
    private let workoutService = WorkoutService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading workouts...")
                } else if workouts.isEmpty {
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "figure.walk",
                        description: Text("Complete a workout to see it here")
                    )
                } else {
                    List(workouts, id: \.uuid) { workout in
                        NavigationLink(
                            destination: WorkoutDetailView(
                                workout: workout, workoutService: workoutService)
                        ) {
                            WorkoutRowView(workout: workout)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .task {
                await loadWorkouts()
            }
            .refreshable {
                await loadWorkouts()
            }
        }
    }

    private func loadWorkouts() async {
        print("[HistoryView] Loading workouts...")
        isLoading = true
        workouts = await workoutService.fetchRecentWorkouts(limit: 20)
        isLoading = false
        print("[HistoryView] Loaded \(workouts.count) workouts")
    }
}

struct WorkoutRowView: View {
    let workout: HKWorkout

    private var activityIcon: String {
        switch workout.workoutActivityType {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .hiking: return "figure.hiking"
        default: return "figure.walk"
        }
    }

    private var activityColor: Color {
        switch workout.workoutActivityType {
        case .walking: return .green
        case .running: return .orange
        case .hiking: return .brown
        default: return .green
        }
    }

    private var formattedDuration: String {
        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedDistance: String {
        let meters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let km = meters / 1000.0
        return String(format: "%.2f km", km)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startDate)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: activityIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(activityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutActivityType.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDuration)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Text(formattedDistance)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WorkoutDetailView: View {
    let workout: HKWorkout
    let workoutService: WorkoutService

    @State private var routeLocations: [CLLocation] = []
    @State private var heartRateData: [HeartRateSample] = []
    @State private var cadenceData: [CadenceSample] = []
    @State private var paceData: [PaceSample] = []
    @State private var statistics: WorkoutStatistics = .empty
    @State private var isLoading = true

    private var totalDistance: Double {
        workout.totalDistance?.doubleValue(for: .meter()) ?? 0
    }

    private var formattedDuration: String {
        let hours = Int(workout.duration) / 3600
        let minutes = (Int(workout.duration) % 3600) / 60
        let seconds = Int(workout.duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedDistance: String {
        let km = totalDistance / 1000.0
        return String(format: "%.2f", km)
    }

    private var formattedCalories: String {
        let kcal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        return String(format: "%.0f", kcal)
    }

    private var formattedPace: String {
        if totalDistance > 0 {
            let paceSecondsPerKm = workout.duration / (totalDistance / 1000.0)
            let minutes = Int(paceSecondsPerKm) / 60
            let seconds = Int(paceSecondsPerKm) % 60
            return String(format: "%d'%02d\"", minutes, seconds)
        }
        return "--'--\""
    }

    private var formattedElevationGain: String {
        return String(format: "+%.0fm", statistics.elevationGain)
    }

    private var formattedAvgHR: String {
        if let hr = statistics.averageHeartRate {
            return String(format: "%.0f bpm", hr)
        }
        return "-- bpm"
    }

    private var activityColor: Color {
        switch workout.workoutActivityType {
        case .walking: return .green
        case .running: return .orange
        case .hiking: return .brown
        default: return .green
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                if isLoading {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 250)
                        .overlay(ProgressView())
                        .padding(.horizontal)
                } else if !statistics.routeSegments.isEmpty {
                    ZStack(alignment: .bottomTrailing) {
                        PaceColoredMap(
                            segments: statistics.routeSegments,
                            activityColor: activityColor
                        )
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        PaceLegend()
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                    .padding(.horizontal)
                } else if !routeLocations.isEmpty {

                    SimpleRouteMap(locations: routeLocations, color: activityColor)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: "Duration", value: formattedDuration, icon: "clock.fill",
                        iconColor: .red)
                    StatCard(
                        title: "Distance", value: "\(formattedDistance) km",
                        icon: "point.topleft.down.to.point.bottomright.curvepath.fill",
                        iconColor: .blue)
                    StatCard(
                        title: "Avg Pace", value: formattedPace, icon: "speedometer",
                        iconColor: .green)
                    StatCard(
                        title: "Calories", value: "\(formattedCalories) kcal", icon: "flame.fill",
                        iconColor: .orange)
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: "Elevation", value: formattedElevationGain, icon: "arrow.up.right",
                        iconColor: .purple)
                    StatCard(
                        title: "Avg HR", value: formattedAvgHR, icon: "heart.fill", iconColor: .pink
                    )
                }
                .padding(.horizontal)

                PaceChart(
                    paceData: paceData,
                    activityColor: activityColor,
                    averagePace: statistics.averagePace,
                    workoutDuration: workout.duration
                )
                .padding(.horizontal)

                //                CadenceChart(
                //                    cadenceData: cadenceData,
                //                    activityColor: activityColor
                //                )
                //                .padding(.horizontal)
                //
                //                HeartRateChart(
                //                    heartRateData: heartRateData,
                //                    averageHR: statistics.averageHeartRate,
                //                    maxHR: statistics.maxHeartRate
                //                )
                //                .padding(.horizontal)

                SplitsView(splits: statistics.splits)
                    .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle(workout.workoutActivityType.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadWorkoutData()
        }
    }

    private func loadWorkoutData() async {
        print("[WorkoutDetailView] Loading workout data...")
        isLoading = true

        async let routeTask = workoutService.fetchRoute(for: workout)
        async let hrTask = workoutService.fetchHeartRateData(for: workout)
        async let cadenceTask = workoutService.fetchCadenceData(for: workout)

        routeLocations = await routeTask
        heartRateData = await hrTask
        cadenceData = await cadenceTask

        // Calculate pace data from route locations
        paceData = calculatePaceData(from: routeLocations)

        statistics = WorkoutStatsCalculator.calculate(
            routeLocations: routeLocations,
            heartRateSamples: heartRateData,
            totalDuration: workout.duration,
            totalDistance: totalDistance
        )

        isLoading = false
        print(
            "[WorkoutDetailView] Loaded \(routeLocations.count) route points, \(heartRateData.count) HR samples, \(cadenceData.count) cadence samples, \(paceData.count) pace samples"
        )
    }

    private func calculatePaceData(from locations: [CLLocation]) -> [PaceSample] {
        guard locations.count >= 2 else { return [] }

        var samples: [PaceSample] = []
        let segmentSize = max(1, locations.count / 50)  // Aim for ~50 bars

        var i = 0
        while i < locations.count - 1 {
            let endIndex = min(i + segmentSize, locations.count - 1)
            let startLoc = locations[i]
            let endLoc = locations[endIndex]

            let distance = endLoc.distance(from: startLoc)
            let time = endLoc.timestamp.timeIntervalSince(startLoc.timestamp)

            if time > 0 && distance > 0 {
                let paceSecondsPerKm = (time / distance) * 1000
                // Filter out unreasonable pace values (slower than 30 min/km or faster than 2 min/km)
                if paceSecondsPerKm > 120 && paceSecondsPerKm < 1800 {
                    samples.append(
                        PaceSample(date: startLoc.timestamp, paceSecondsPerKm: paceSecondsPerKm))
                }
            }

            i = endIndex
        }

        return samples
    }
}

struct SimpleRouteMap: View {
    let locations: [CLLocation]
    let color: Color

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            if locations.count >= 2 {
                MapPolyline(coordinates: locations.map { $0.coordinate })
                    .stroke(color, lineWidth: 4)
            }
        }
        .onAppear {
            if let first = locations.first {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: first.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .red

    var body: some View {
        VStack(spacing: 12) {
            
            HStack {
            ZStack {
//                Circle()
//                    .fill(iconColor)
//                    .frame(width: 14, height: 14)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .walking: return "Walk"
        case .running: return "Run"
        case .hiking: return "Hike"
        default: return "Workout"
        }
    }
}

#Preview {
    StatCard(title: "Duration", value: "1:23:45", icon: "clock.fill")
}
