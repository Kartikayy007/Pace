//
//  SessionControlSheet.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import SwiftUI
import UIKit

struct HoldToConfirmButton: View {
    let icon: String
    let size: CGFloat
    let holdDuration: Double
    let background: Color
    let foreground: Color
    let progressColor: Color
    let onComplete: () -> Void
    
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdTimer: Timer?
    
    var body: some View {
        ZStack {
            if isHolding || holdProgress > 0 {
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: size + 8, height: size + 8)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: holdProgress)
            }
            
            Circle()
                .fill(background)
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundColor(foreground)
        }
        .scaleEffect(isHolding ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isHolding)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        startHold()
                    }
                }
                .onEnded { _ in
                    cancelHold()
                }
        )
    }
    
    private func startHold() {
        isHolding = true
        holdProgress = 0
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        
        let updateInterval: Double = 0.02
        let progressIncrement = CGFloat(updateInterval / holdDuration)
        
        holdTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            holdProgress += progressIncrement
            
            if Int(holdProgress * 100) % 25 == 0 {
                let tickGenerator = UIImpactFeedbackGenerator(style: .light)
                tickGenerator.impactOccurred(intensity: 0.5)
            }
            
            if holdProgress >= 1.0 {
                timer.invalidate()
                holdTimer = nil
                
                let successGenerator = UINotificationFeedbackGenerator()
                successGenerator.notificationOccurred(.success)
                
                isHolding = false
                holdProgress = 0
                onComplete()
            }
        }
    }
    
    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }
}

struct SessionControlSheet: View {
    let activityIcon: String
    let activityColor: Color
    let elapsedTime: TimeInterval
    let ringProgress: Double
    let isPaused: Bool
    let onPause: () -> Void
    let onEnd: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLocked = false
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let centiseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
    
    private var buttonBackground: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
    }
    
    private var buttonForeground: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
//                ZStack {
//                    Circle()
//                        .fill(activityColor.opacity(0.3))
//                        .frame(width: 50, height: 50)
//                    Image(systemName: activityIcon)
//                        .font(.system(size: 22, weight: .semibold))
//                        .foregroundColor(activityColor)
//                }
                
                Spacer()
                
                Text(formattedTime)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .monospacedDigit()
                
                Spacer()
                
//                MoveRing(progress: ringProgress)
//                    .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            if isLocked {
                VStack(spacing: 12) {
                    HoldToConfirmButton(
                        icon: "lock.open.fill",
                        size: 90,
                        holdDuration: 1.5,
                        background: buttonBackground,
                        foreground: buttonForeground,
                        progressColor: activityColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            isLocked = false
                        }
                    }
                    
                    Text("Hold to unlock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 20) {
                    HoldToConfirmButton(
                        icon: "xmark",
                        size: 70,
                        holdDuration: 2.0,
                        background: buttonBackground,
                        foreground: buttonForeground,
                        progressColor: activityColor
                    ) {
                        onEnd()
                    }
                    
                    HoldToConfirmButton(
                        icon: isPaused ? "play.fill" : "pause",
                        size: 90,
                        holdDuration: 2.0,
                        background: buttonBackground,
                        foreground: buttonForeground,
                        progressColor: activityColor
                    ) {
                        onPause()
                    }
                    
                    HoldToConfirmButton(
                        icon: "lock.fill",
                        size: 70,
                        holdDuration: 1.0,
                        background: buttonBackground,
                        foreground: buttonForeground,
                        progressColor: activityColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            isLocked = true
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(height: 220)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SessionControlSheet(
                activityIcon: "figure.walk",
                activityColor: .green,
                elapsedTime: 7.75,
                ringProgress: 0.15,
                isPaused: false,
                onPause: {},
                onEnd: {}
            )
        }
}
