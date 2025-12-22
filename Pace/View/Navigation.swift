//
//  Navigation.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SwiftUI

struct Navigation: View {
    private var settings = SettingsManager.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ActivitesView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Activities")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }
}
