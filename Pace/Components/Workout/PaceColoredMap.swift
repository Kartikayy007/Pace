//
//  PaceColoredMap.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import MapKit
import SwiftUI

struct PaceColoredMap: View {
    let segments: [RouteSegment]
    let activityColor: Color

    @State private var cameraPosition: MapCameraPosition = .automatic

    private func colorForPacePercentile(_ percentile: Double) -> Color {
        if percentile < 0.5 {
            let ratio = percentile * 2.0
            return Color(
                red: ratio,
                green: 0.8,
                blue: 0.0
            )
        } else {
            let ratio = (percentile - 0.5) * 2.0
            return Color(
                red: 0.9,
                green: 0.8 * (1.0 - ratio),
                blue: 0.0
            )
        }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(segments.filter { $0.coordinates.count >= 2 }) { segment in
                MapPolyline(coordinates: segment.coordinates)
                    .stroke(
                        colorForPacePercentile(segment.pacePercentile),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .mapStyle(.standard)
        .onAppear {
            setupCamera()
        }
    }

    private func setupCamera() {
        guard let firstSegment = segments.first,
            let firstCoord = firstSegment.coordinates.first
        else {
            return
        }

        var minLat = firstCoord.latitude
        var maxLat = firstCoord.latitude
        var minLon = firstCoord.longitude
        var maxLon = firstCoord.longitude

        for segment in segments {
            for coord in segment.coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLon = min(minLon, coord.longitude)
                maxLon = max(maxLon, coord.longitude)
            }
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct PaceLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Fast")
                .font(.caption2)
                .foregroundColor(.secondary)

            LinearGradient(
                colors: [.green, .yellow, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 60, height: 8)
            .clipShape(Capsule())

            Text("Slow")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
