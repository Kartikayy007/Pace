import SwiftUI
import UIKit

struct ActiveSessionView: View {
    @Bindable var viewModel: ActivityViewModel
    let onEnd: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showControlSheet = true
    
    private var paceString: String {
        if viewModel.currentPace > 0 {
            let minutes = Int(viewModel.currentPace) / 60
            let seconds = Int(viewModel.currentPace) % 60
            return String(format: "%d'%02d\"", minutes, seconds)
        }
        return "--'--\""
    }
    
    private var isPaused: Bool {
        viewModel.sessionState == .paused
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    SessionMetricCard(
                        value: String(format: "%.2f", viewModel.currentDistance),
                        label: "kilometres"
                    )
                    Spacer()
                    SessionMetricCard(
                        value: paceString,
                        label: "Pace"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                MoveRing(progress: viewModel.ringProgress)
                    .frame(width: 220, height: 220)
                
                Spacer()
                
                Color.clear
                    .frame(height: 220)
            }
        }
        .sheet(isPresented: $showControlSheet) {
            SessionControlSheet(
                activityIcon: viewModel.currentActivityIcon,
                activityColor: viewModel.currentActivityColor,
                elapsedTime: viewModel.elapsedTime,
                ringProgress: viewModel.ringProgress,
                isPaused: isPaused,
                onPause: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    if isPaused {
                        viewModel.resumeSession()
                    } else {
                        viewModel.pauseSession()
                    }
                },
                onEnd: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    onEnd()
                }
            )
        }
    }
}

#Preview {
    ActiveSessionView(viewModel: ActivityViewModel(), onEnd: {})
}
