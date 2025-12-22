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
    
    @State private var hasDistanceGoal: Bool = false
    @State private var hasTimeGoal: Bool = false
    @State private var localDistanceGoal: Double = 5.0
    @State private var localTimeGoal: Int = 30
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("START OPTIONS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            SettingsRow {
                                Toggle(isOn: $countdownEnabled) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 20))
                                            .foregroundColor(.orange)
                                            .frame(width: 28)
                                        Text("Countdown")
                                            .font(.system(size: 17))
                                    }
                                }
                            }
                            
                            if countdownEnabled {
                                Divider()
                                    .padding(.leading, 52)
                                
                                SettingsRow {
                                    HStack {
                                        Text("Seconds")
                                            .font(.system(size: 17))
                                        Spacer()
                                        Picker("", selection: $countdownSeconds) {
                                            Text("3").tag(3)
                                            Text("5").tag(5)
                                            Text("10").tag(10)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 140)
                                    }
                                }
                            }
                        }
                        .glassEffect(.regular)
                        .cornerRadius(16)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GOALS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            SettingsRow {
                                Toggle(isOn: $hasDistanceGoal) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                            .frame(width: 28)
                                        Text("Distance Goal")
                                            .font(.system(size: 17))
                                    }
                                }
                            }
                            .onChange(of: hasDistanceGoal) { _, newValue in
                                distanceGoal = newValue ? localDistanceGoal : nil
                            }
                            
                            if hasDistanceGoal {
                                Divider()
                                    .padding(.leading, 52)
                                
                                SettingsRow {
                                    HStack {
                                        Text("Target")
                                            .font(.system(size: 17))
                                        Spacer()
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                if localDistanceGoal > 0.5 {
                                                    localDistanceGoal -= 0.5
                                                    distanceGoal = localDistanceGoal
                                                }
                                            }) {
                                                Image(systemName: "minus")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 32, height: 32)
                                                    .glassEffect(.regular)
                                                    .cornerRadius(8)
                                            }
                                            
                                            Text(String(format: "%.1f km", localDistanceGoal))
                                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                                .frame(width: 70)
                                            
                                            Button(action: {
                                                if localDistanceGoal < 100 {
                                                    localDistanceGoal += 0.5
                                                    distanceGoal = localDistanceGoal
                                                }
                                            }) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 32, height: 32)
                                                    .glassEffect(.regular)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsRow {
                                Toggle(isOn: $hasTimeGoal) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.purple)
                                            .frame(width: 28)
                                        Text("Time Goal")
                                            .font(.system(size: 17))
                                    }
                                }
                            }
                            .onChange(of: hasTimeGoal) { _, newValue in
                                timeGoal = newValue ? localTimeGoal : nil
                            }
                            
                            if hasTimeGoal {
                                Divider()
                                    .padding(.leading, 52)
                                
                                SettingsRow {
                                    HStack {
                                        Text("Duration")
                                            .font(.system(size: 17))
                                        Spacer()
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                if localTimeGoal > 5 {
                                                    localTimeGoal -= 5
                                                    timeGoal = localTimeGoal
                                                }
                                            }) {
                                                Image(systemName: "minus")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 32, height: 32)
                                                    .glassEffect(.regular)
                                                    .cornerRadius(8)
                                            }
                                            
                                            Text("\(localTimeGoal) min")
                                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                                .frame(width: 70)
                                            
                                            Button(action: {
                                                if localTimeGoal < 180 {
                                                    localTimeGoal += 5
                                                    timeGoal = localTimeGoal
                                                }
                                            }) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 32, height: 32)
                                                    .glassEffect(.regular)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .glassEffect(.regular)
                        .cornerRadius(16)
                        
                        Text("Set a goal to be notified when you reach your target.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(.clear)
            .scrollContentBackground(.hidden)
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
                hasDistanceGoal = distanceGoal != nil
                hasTimeGoal = timeGoal != nil
                if let distance = distanceGoal {
                    localDistanceGoal = distance
                }
                if let time = timeGoal {
                    localTimeGoal = time
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }
}

struct SettingsRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}
