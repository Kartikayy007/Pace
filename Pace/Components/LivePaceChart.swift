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
    
    private var totalSteps: Int {
        stepData.reduce(0) { $0 + $1.steps }
    }
    
    private var currentHourSteps: Int {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return stepData.first { $0.hour == currentHour }?.steps ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(currentHourSteps)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                Text("STEPS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
            }

            
            Chart(stepData) { point in
                BarMark(
                    x: .value("Hour", point.hour),
                    y: .value("Steps", point.steps)
                )
                .foregroundStyle(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(formatHour(hour))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                }
            }
            .chartXScale(domain: 0...23)
            .frame(height: 80)

            HStack(spacing: 4) {
                Text("TOTAL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                Text("\(totalSteps.formatted())")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                Text("STEPS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12:00"
        } else if hour < 12 {
            return "\(hour):00"
        } else if hour == 12 {
            return "12:00"
        } else {
            return "\(hour - 12):00"
        }
    }
}

#Preview {
    let mockData: [StepDataPoint] = (0..<24).map { hour in
        let steps: Int
        if hour < 6 {
            steps = 0
        } else if hour < 12 {
            steps = Int.random(in: 0...200)
        } else if hour < 18 {
            steps = Int.random(in: 500...2000)
        } else {
            steps = Int.random(in: 200...1000)
        }
        return StepDataPoint(hour: hour, steps: steps)
    }

    LivePaceChart(stepData: mockData)
        .padding()
        .background(Color.black)
}
