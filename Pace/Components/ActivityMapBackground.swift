//
//  ActivityMapBackground.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import MapKit
import SwiftUI

struct ActivityMapBackground: View {
    @Binding var cameraPosition: MapCameraPosition
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .systemBackground).opacity(0.7),
                    .clear,
                    .clear,
                    Color(uiColor: .systemBackground).opacity(0.5),
                    Color(uiColor: .systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
