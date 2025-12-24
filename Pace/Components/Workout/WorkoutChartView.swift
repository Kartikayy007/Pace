//
//  WorkoutChartView.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import Charts
import SwiftUI

struct CadenceChart: View {
    let cadenceData: [CadenceSample]
    let activityColor: Color

    private var averageCadence: Double {
        guard !cadenceData.isEmpty else { return 0 }
        return cadenceData.map { $0.stepsPerMinute }.reduce(0, +) / Double(cadenceData.count)
    }

    private var maxCadence: Double {
        cadenceData.map { $0.stepsPerMinute }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cadence")
                    .font(.headline)
                Spacer()
                if !cadenceData.isEmpty {
                    Text("Avg: \(Int(averageCadence)) spm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if cadenceData.isEmpty {
                Text("No cadence data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(cadenceData) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value("SPM", sample.stepsPerMinute)
                        )
                        .foregroundStyle(activityColor)
                        .interpolationMethod(.catmullRom)
                    }

                    if averageCadence > 0 {
                        RuleMark(y: .value("Average", averageCadence))
                            .foregroundStyle(activityColor.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let spm = value.as(Double.self) {
                                Text("\(Int(spm))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                    }
                }
                .frame(height: 150)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(activityColor)
                            .frame(width: 8, height: 8)
                        Text("Steps/min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(activityColor.opacity(0.5))
                            .frame(width: 12, height: 2)
                        Text("Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HeartRateChart: View {
    let heartRateData: [HeartRateSample]
    let averageHR: Double?
    let maxHR: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Heart Rate")
                    .font(.headline)
                Spacer()
                if let avg = averageHR {
                    Text("Avg: \(Int(avg)) bpm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if heartRateData.isEmpty {
                Text("No heart rate data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(heartRateData) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value("BPM", sample.bpm)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                    }

                    if let avg = averageHR {
                        RuleMark(y: .value("Average", avg))
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let bpm = value.as(Double.self) {
                                Text("\(Int(bpm))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SplitsView: View {
    let splits: [KilometerSplit]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Splits")
                .font(.headline)

            if splits.isEmpty {
                Text("No split data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 0) {

                    HStack {
                        Text("KM")
                            .frame(width: 40, alignment: .leading)
                        Text("TIME")
                            .frame(width: 60, alignment: .leading)
                        Text("PACE")
                            .frame(width: 70, alignment: .leading)
                        Spacer()
                        Text("CHANGE")
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                    Divider()

                    ForEach(splits) { split in
                        SplitRow(split: split)
                        if split.id != splits.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SplitRow: View {
    let split: KilometerSplit

    private var formattedDuration: String {
        let minutes = Int(split.duration) / 60
        let seconds = Int(split.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack {
            Text("\(split.kilometer)")
                .font(.system(.body, design: .rounded, weight: .medium))
                .frame(width: 40, alignment: .leading)

            Text(formattedDuration)
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .leading)

            Text(split.formattedPace)
                .font(.system(.body, design: .monospaced))
                .frame(width: 70, alignment: .leading)

            Spacer()

            if let changeText = split.formattedPaceChange {
                Text(changeText)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .foregroundColor(split.isFaster ? .green : .red)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text("—")
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
    }
}
