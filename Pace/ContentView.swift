//
//  ContentView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SceneKit
import SwiftUI

struct ContentView: View {

    private let animationFile = "Walking.dae"

    var body: some View {
        SceneView(
            scene: CharacterSceneService.createWalkingScene(fileName: animationFile),
            options: [.autoenablesDefaultLighting]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
