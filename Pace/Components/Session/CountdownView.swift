import SwiftUI
import UIKit

struct CountdownView: View {
    let count: Int
    let activityColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Ready")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text("\(count)")
                    .font(.system(size: 160, weight: .bold, design: .rounded))
                    .foregroundColor(activityColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: count)
            }
        }
        .onChange(of: count) { oldValue, newValue in
            triggerCountdownHaptic(for: newValue)
        }
        .onAppear {
            triggerCountdownHaptic(for: count)
        }
    }
    
    private func triggerCountdownHaptic(for value: Int) {
        if value == 1 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}

#Preview {
    CountdownView(count: 3, activityColor: .green)
}
