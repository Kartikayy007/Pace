//
//  HomeView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SceneKit
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = HomeViewModel()

    private var sceneConfig: CharacterSceneConfig {
        let bgColor: UIColor = colorScheme == .dark ? .black : .white
        return CharacterSceneConfig(
            animationFileName: "Walking1.dae",
            characterHeight: 1.5,
            mirrorCharacter: false,
            cameraOffset: SCNVector3(x: 0, y: 0.5, z: 4),
            lookAtYOffset: -0.1,
            fieldOfView: 35,
            backgroundColor: bgColor,
            showFloor: true,
            floorColor: bgColor,
            showShadow: true
        )
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
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
                        ActivityRingView(viewModel: viewModel)
                    }
                    .padding()
                    .padding(.trailing, 12)

                    VStack {
                        LivePaceChart(stepData: viewModel.hourlySteps)
                            .padding(.horizontal)
                            .padding(.top, 100)

                        Spacer()
                    }
                }
            }
            .background(backgroundColor)
            .ignoresSafeArea()
            .onAppear {
                viewModel.startTracking()
            }
            .onDisappear {
                viewModel.stopTracking()
            }
    }
}

#Preview {
    HomeView()
}
