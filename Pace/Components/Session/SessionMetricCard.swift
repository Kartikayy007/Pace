import SwiftUI

struct SessionMetricCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        SessionMetricCard(value: "0.00", label: "kilometres")
        SessionMetricCard(value: "156", label: "Calories")
        SessionMetricCard(value: "--'--\"", label: "Pace")
    }
    .padding()
    .background(Color.black)
}
