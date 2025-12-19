//
//  Navigation.swift
//  Pace
//
//  Created by kartikay on 19/12/25.
//

import SwiftUI

struct Navigation: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
        }
    }
}
