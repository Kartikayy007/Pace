//
//  ActivityPickerSheet.swift
//  Pace
//
//  Created by kartikay on 21/12/25.
//

import SwiftUI

struct ActivityPickerSheet: View {
    let activities: [Activity]
    @Binding var selectedActivity: Activity
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List(activities) { activity in
                Button(action: {
                    selectedActivity = activity
                    isPresented = false
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: activity.icon)
                            .font(.system(size: 28))
                            .foregroundColor(activity.color)
                            .frame(width: 50)

                        Text(activity.title)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedActivity.title == activity.title {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Choose Activity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
