//
//  StatRow.swift
//  Pace
//
//  Created by kartikay on 20/12/25.
//

import SwiftUI

struct StatRow: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        StatRow(icon: "figure.walk", iconColor: .red, value: "7,500", label: "Steps")
        StatRow(icon: "location.fill", iconColor: .green, value: "4.5 km", label: "Distance")
        StatRow(icon: "flame.fill", iconColor: .orange, value: "320", label: "Calories")
    }
    .padding()
}
