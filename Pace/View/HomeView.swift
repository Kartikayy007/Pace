//
//  HomeView.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SceneKit
import SwiftUI

private let config = CharacterSceneConfig(
    animationFileName: "Walking1.dae",
    characterHeight: 1.5,
    mirrorCharacter: false,
    cameraOffset: SCNVector3(x: 0, y: 0.5, z: 4),
    lookAtYOffset: 0,
    fieldOfView: 35,
    backgroundColor: .black
)
struct HomeView: View {
    var body: some View {
        ZStack {
            

            HStack {
                Spacer()
                ActivityRingView()

            }.padding()
                .padding(.trailing, 12)
            
            HStack {

                SceneView(
                    scene:
                        CharacterSceneService
                        .createScene(with: config),
                    options: [.autoenablesDefaultLighting]
                )
                .ignoresSafeArea()
                .frame(width: .infinity)

                Spacer()

            }.padding(.trailing, 162)
        }.background(.black)

    }
}

#Preview {
    HomeView()
}
