//
//  ActiveSessionView.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import MapKit
import SwiftUI
import UIKit

struct ActiveSessionView: View {
    @Bindable var viewModel: ActivityViewModel
    let onEnd: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showControlSheet = true
    @State private var selectedPage = 0
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    private var paceString: String {
        if viewModel.currentPace > 0 {
            let minutes = Int(viewModel.currentPace) / 60
            let seconds = Int(viewModel.currentPace) % 60
            return String(format: "%d'%02d\"", minutes, seconds)
        }
        return "--'--\""
    }

    private var distanceString: String {
        let distanceKm = viewModel.currentDistance
        let distanceMeters = distanceKm * 1000

        if distanceMeters < 1000 {
            return String(format: "%.0fm", distanceMeters)
        } else {
            return String(format: "%.1fkm", distanceKm)
        }
    }

    private var caloriesString: String {
        let cal = viewModel.currentCalories
        if cal < 1 {
            return "0"
        }
        return String(format: "%.0f", cal)
    }

    private var cadenceString: String {
        let cadence = viewModel.currentCadence
        if cadence > 0 {
            return String(format: "%.0f", cadence)
        }
        return "--"
    }

    private var heartRateString: String {
        let hr = viewModel.currentHeartRate
        if hr > 0 {
            return String(format: "%.0f", hr)
        }
        return "--"
    }

    private var isPaused: Bool {
        viewModel.sessionState == .paused
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }

    var body: some View {
        ZStack {
            
            TabView(selection: $selectedPage) {

                ZStack {
                    Map(position: $mapCameraPosition) {
                        if viewModel.liveRoute.count >= 2 {
                            MapPolyline(coordinates: viewModel.liveRoute.map { $0.coordinate })
                                .stroke(
                                    viewModel.currentActivityColor,
                                    style: StrokeStyle(
                                        lineWidth: 5, lineCap: .round, lineJoin: .round)
                                )
                        }
                        UserAnnotation()
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .ignoresSafeArea()
                    .onChange(of: viewModel.liveRoute) { _, newRoute in
                        updateMapCamera(for: newRoute)
                    }

                    
                    LinearGradient(
                        colors: [
                            backgroundColor,
                            backgroundColor.opacity(0.6),
                            .clear,
                            .clear,
                            .clear,
                            backgroundColor.opacity(0.6),
                            backgroundColor,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                .tag(0)

                
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    VStack(spacing: 16) {
                        MoveRing(progress: viewModel.ringProgress)
                            .frame(width: 200, height: 200)

                        VStack(spacing: 4) {
                            Text("\(Int(viewModel.ringProgress * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("Overall Progress")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .offset(y: -40)
                }
                .tag(1)
                

                
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(cadenceString)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text("spm")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            Text("cadence")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .frame(width: 100)

                        VStack(spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(caloriesString)
                                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                Text("kcal")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            Text("active calories")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .offset(y: -60)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    SessionMetricCard(
                        value: distanceString,
                        label: "Distance"
                    )
                    Spacer()
                    SessionMetricCard(
                        value: paceString,
                        label: "Pace"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                index == selectedPage
                                    ? Color.primary : Color.secondary.opacity(0.4)
                            )
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: selectedPage)
                    }
                }
                .padding(.bottom, 16)

                Color.clear
                    .frame(height: 220)
            }
        }
        .sheet(isPresented: $showControlSheet) {
            SessionControlSheet(
                activityIcon: viewModel.currentActivityIcon,
                activityColor: viewModel.currentActivityColor,
                elapsedTime: viewModel.elapsedTime,
                ringProgress: viewModel.ringProgress,
                isPaused: isPaused,
                onPause: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    if isPaused {
                        viewModel.resumeSession()
                    } else {
                        viewModel.pauseSession()
                    }
                },
                onEnd: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    onEnd()
                }
            )
        }
        .sensoryFeedback(.selection, trigger: selectedPage)
        .onAppear {
            mapCameraPosition = viewModel.cameraPosition
        }
    }

    private func updateMapCamera(for route: [CLLocation]) {
        guard let lastLocation = route.last else {
            mapCameraPosition = viewModel.cameraPosition
            return
        }

        mapCameraPosition = .camera(
            MapCamera(
                centerCoordinate: lastLocation.coordinate,
                distance: 500
            )
        )
    }
}

#Preview {
    ActiveSessionView(viewModel: ActivityViewModel(), onEnd: {})
}
