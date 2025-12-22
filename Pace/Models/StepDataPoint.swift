//
//  StepDataPoint.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import Foundation

struct StepDataPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let steps: Int

    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H"
        let date =
            Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
