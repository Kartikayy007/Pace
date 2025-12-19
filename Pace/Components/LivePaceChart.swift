//
//  LivePaceChart.swift
//  Pace
//
//  Created by kartikay on 20/12/25.
//

import Charts
import SwiftUI

struct LivePaceChart: View {
    let stepData: [StepDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Activity")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
                .tracking(1)

            Chart(stepData) { point in
                BarMark(
                    x: .value("Hour", point.hour),
                    y: .value("Steps", point.steps)
                )
                .foregroundStyle(Color.red)
                .cornerRadius(2)
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour)")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let steps = value.as(Int.self) {
                            Text("\(steps)")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
            .chartXScale(domain: 0...23)
            .frame(height: 100)

            Text("steps per hour")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
    }
}

#Preview {
    var mockData: [StepDataPoint] = []
    for hour in 0..<24 {
        let steps = [
            0, 200, 500, 100, 50, 0, 800, 1200, 900, 400, 300, 600, 1500, 800, 200, 100, 0, 300,
            500, 200, 100, 50, 0, 0,
        ][hour]
        mockData.append(StepDataPoint(hour: hour, steps: steps))
    }

    return LivePaceChart(stepData: mockData)
        .padding()
        .background(Color.black)
}
