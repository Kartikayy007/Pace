//
//  HomeView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SceneKit
import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var pedometerManager = PedometerManager()

    private var sceneConfig: CharacterSceneConfig {
        CharacterSceneConfig(
            animationFileName: "Walking1.dae",
            characterHeight: 1.5,
            mirrorCharacter: false,
            cameraOffset: SCNVector3(x: 0, y: 0.5, z: 4),
            lookAtYOffset: -0.1,
            fieldOfView: 35,
            backgroundColor: colorScheme == .dark ? .black : .white
        )
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.2)

                        HStack {
                            SceneView(
                                scene: CharacterSceneService.createScene(with: sceneConfig),
                                options: [.autoenablesDefaultLighting]
                            )
                            .frame(width: geometry.size.width * 0.65)

                            Spacer()
                        }
                    }

                    
                    HStack {
                        Spacer()
                        ActivityRingView(pedometerManager: pedometerManager)
                    }
                    .padding()
                    .padding(.trailing, 12)

                    
                    VStack {
                        LivePaceChart(stepData: pedometerManager.hourlySteps)
                            .padding(.horizontal)
                            .padding(.top, 100)

                        Spacer()
                    }
                }
            }
            .background(backgroundColor)
            .ignoresSafeArea()
            .navigationTitle("Pace")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                pedometerManager.startTracking()
            }
            .onDisappear {
                pedometerManager.stopTracking()
            }
        }
    }
}

#Preview {
    HomeView()
}
