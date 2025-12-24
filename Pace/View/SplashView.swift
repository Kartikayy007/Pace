//
//  SplashView.swift
//  Pace
//
//  Created by kartikay on 24/12/25.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    private var logoImageName: String {
        colorScheme == .dark ? "SplashLogoDark" : "SplashLogoLight"
    }

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(logoImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Text("Pace")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .opacity(textOpacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }

                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    textOpacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
