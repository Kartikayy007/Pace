import HealthKit
import HealthKitUI
import SwiftUI

struct MoveRing: UIViewRepresentable {
    let progress: Double
    
    func makeUIView(context: Context) -> HKActivityRingView {
        let ringView = HKActivityRingView()
        ringView.setActivitySummary(createSummary(), animated: false)
        return ringView
    }
    
    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.setActivitySummary(createSummary(), animated: true)
    }
    
    private func createSummary() -> HKActivitySummary {
        let summary = HKActivitySummary()
        summary.activityMoveMode = .appleMoveTime
        summary.appleMoveTime = HKQuantity(unit: .minute(), doubleValue: progress * 90)
        summary.appleMoveTimeGoal = HKQuantity(unit: .minute(), doubleValue: 90)
        return summary
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MoveRing(progress: 0.25)
            .frame(width: 200, height: 200)
    }
}
