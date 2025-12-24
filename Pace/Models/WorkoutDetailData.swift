//
//  WorkoutDetailData.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//

import CoreLocation
import Foundation

struct RouteSmoothing {
    static func douglasPeucker(locations: [CLLocation], epsilon: Double) -> [CLLocation] {
        guard locations.count > 2 else { return locations }

        var maxDistance: Double = 0
        var maxIndex = 0

        let start = locations.first!
        let end = locations.last!

        for i in 1..<(locations.count - 1) {
            let distance = perpendicularDistance(
                point: locations[i], lineStart: start, lineEnd: end)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        if maxDistance > epsilon {
            let leftPart = douglasPeucker(
                locations: Array(locations[0...maxIndex]), epsilon: epsilon)
            let rightPart = douglasPeucker(
                locations: Array(locations[maxIndex...]), epsilon: epsilon)

            return Array(leftPart.dropLast()) + rightPart
        } else {

            return [start, end]
        }
    }

    private static func perpendicularDistance(
        point: CLLocation, lineStart: CLLocation, lineEnd: CLLocation
    ) -> Double {
        let x0 = point.coordinate.latitude
        let y0 = point.coordinate.longitude
        let x1 = lineStart.coordinate.latitude
        let y1 = lineStart.coordinate.longitude
        let x2 = lineEnd.coordinate.latitude
        let y2 = lineEnd.coordinate.longitude

        let numerator = abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1)
        let denominator = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2))

        guard denominator > 0 else { return 0 }

        return (numerator / denominator) * 111000
    }

    static func movingAverage(locations: [CLLocation], windowSize: Int = 3) -> [CLLocation] {
        guard locations.count > windowSize else { return locations }

        var smoothed: [CLLocation] = []
        let halfWindow = windowSize / 2

        for i in 0..<locations.count {
            let start = max(0, i - halfWindow)
            let end = min(locations.count - 1, i + halfWindow)

            var avgLat: Double = 0
            var avgLon: Double = 0
            var count = 0

            for j in start...end {
                avgLat += locations[j].coordinate.latitude
                avgLon += locations[j].coordinate.longitude
                count += 1
            }

            avgLat /= Double(count)
            avgLon /= Double(count)

            let smoothedLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                altitude: locations[i].altitude,
                horizontalAccuracy: locations[i].horizontalAccuracy,
                verticalAccuracy: locations[i].verticalAccuracy,
                timestamp: locations[i].timestamp
            )
            smoothed.append(smoothedLocation)
        }

        return smoothed
    }

    static func catmullRomSpline(
        locations: [CLLocation], pointsPerSegment: Int = 5, alpha: Double = 0.5
    ) -> [CLLocation] {
        guard locations.count >= 4 else { return locations }

        var result: [CLLocation] = []

        for i in 0..<(locations.count - 1) {

            let p0 = locations[max(0, i - 1)]
            let p1 = locations[i]
            let p2 = locations[min(locations.count - 1, i + 1)]
            let p3 = locations[min(locations.count - 1, i + 2)]

            if i == 0 {
                result.append(p1)
            }

            for j in 1...pointsPerSegment {
                let t = Double(j) / Double(pointsPerSegment)

                let interpolated = catmullRomPoint(
                    p0: p0.coordinate,
                    p1: p1.coordinate,
                    p2: p2.coordinate,
                    p3: p3.coordinate,
                    t: t,
                    alpha: alpha
                )

                let altitude = p1.altitude + (p2.altitude - p1.altitude) * t
                let timeInterval = p2.timestamp.timeIntervalSince(p1.timestamp) * t
                let timestamp = p1.timestamp.addingTimeInterval(timeInterval)

                let accuracy = (p1.horizontalAccuracy + p2.horizontalAccuracy) / 2
                let vAccuracy = (p1.verticalAccuracy + p2.verticalAccuracy) / 2

                let interpolatedLocation = CLLocation(
                    coordinate: interpolated,
                    altitude: altitude,
                    horizontalAccuracy: accuracy,
                    verticalAccuracy: vAccuracy,
                    timestamp: timestamp
                )

                result.append(interpolatedLocation)
            }
        }

        return result
    }

    private static func catmullRomPoint(
        p0: CLLocationCoordinate2D,
        p1: CLLocationCoordinate2D,
        p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D,
        t: Double,
        alpha: Double
    ) -> CLLocationCoordinate2D {

        func getT(
            _ t: Double, _ p0: CLLocationCoordinate2D, _ p1: CLLocationCoordinate2D, _ alpha: Double
        ) -> Double {
            let dx = p1.latitude - p0.latitude
            let dy = p1.longitude - p0.longitude
            let dist = sqrt(dx * dx + dy * dy)
            return t + pow(dist, alpha)
        }

        let t0: Double = 0
        let t1 = getT(t0, p0, p1, alpha)
        let t2 = getT(t1, p1, p2, alpha)
        let t3 = getT(t2, p2, p3, alpha)

        let tActual = t1 + t * (t2 - t1)

        guard t1 != t0, t2 != t1, t3 != t2, t2 != t0, t3 != t1 else {

            return CLLocationCoordinate2D(
                latitude: p1.latitude + (p2.latitude - p1.latitude) * t,
                longitude: p1.longitude + (p2.longitude - p1.longitude) * t
            )
        }

        func lerp(
            _ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, _ ta: Double, _ tb: Double,
            _ t: Double
        ) -> CLLocationCoordinate2D {
            let factor = (t - ta) / (tb - ta)
            return CLLocationCoordinate2D(
                latitude: a.latitude + (b.latitude - a.latitude) * factor,
                longitude: a.longitude + (b.longitude - a.longitude) * factor
            )
        }

        let a1 = lerp(p0, p1, t0, t1, tActual)
        let a2 = lerp(p1, p2, t1, t2, tActual)
        let a3 = lerp(p2, p3, t2, t3, tActual)

        let b1 = lerp(a1, a2, t0, t2, tActual)
        let b2 = lerp(a2, a3, t1, t3, tActual)

        let c = lerp(b1, b2, t1, t2, tActual)

        return c
    }
}

struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
}

struct CadenceSample: Identifiable {
    let id = UUID()
    let date: Date
    let stepsPerMinute: Double
}

struct KilometerSplit: Identifiable {
    let id = UUID()
    let kilometer: Int
    let duration: TimeInterval
    let pace: TimeInterval
    let paceChange: TimeInterval?
    let elevationChange: Double
    let startLocation: CLLocation?
    let endLocation: CLLocation?

    var formattedPace: String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var formattedPaceChange: String? {
        guard let change = paceChange else { return nil }
        let absChange = abs(change)
        let minutes = Int(absChange) / 60
        let seconds = Int(absChange) % 60
        let sign = change > 0 ? "+" : "-"
        return String(format: "%@%d'%02d\"", sign, minutes, seconds)
    }

    var isFaster: Bool {
        guard let change = paceChange else { return false }
        return change < 0
    }
}

struct ElevationDataPoint: Identifiable {
    let id = UUID()
    let distance: Double
    let altitude: Double
}

struct PaceDataPoint: Identifiable {
    let id = UUID()
    let distance: Double
    let pace: Double
}

struct PaceSample: Identifiable {
    let id = UUID()
    let date: Date
    let paceSecondsPerKm: Double
}

struct RouteSegment: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let pace: Double
    let pacePercentile: Double
}

struct WorkoutStatistics {
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let minHeartRate: Double?
    let elevationGain: Double
    let elevationLoss: Double
    let averagePace: TimeInterval
    let maxSpeed: Double?
    let splits: [KilometerSplit]
    let elevationData: [ElevationDataPoint]
    let paceData: [PaceDataPoint]
    let heartRateData: [HeartRateSample]
    let cadenceData: [CadenceSample]
    let routeSegments: [RouteSegment]

    static let empty = WorkoutStatistics(
        averageHeartRate: nil,
        maxHeartRate: nil,
        minHeartRate: nil,
        elevationGain: 0,
        elevationLoss: 0,
        averagePace: 0,
        maxSpeed: nil,
        splits: [],
        elevationData: [],
        paceData: [],
        heartRateData: [],
        cadenceData: [],
        routeSegments: []
    )
}

struct WorkoutStatsCalculator {

    static func calculate(
        routeLocations: [CLLocation],
        heartRateSamples: [HeartRateSample],
        totalDuration: TimeInterval,
        totalDistance: Double
    ) -> WorkoutStatistics {

        guard routeLocations.count >= 2 else {
            let hrValues = heartRateSamples.map { $0.bpm }
            let avgHR = hrValues.isEmpty ? nil : hrValues.reduce(0, +) / Double(hrValues.count)
            let avgPace = totalDistance > 0 ? totalDuration / (totalDistance / 1000.0) : 0

            return WorkoutStatistics(
                averageHeartRate: avgHR,
                maxHeartRate: hrValues.max(),
                minHeartRate: hrValues.min(),
                elevationGain: 0,
                elevationLoss: 0,
                averagePace: avgPace,
                maxSpeed: nil,
                splits: [],
                elevationData: [],
                paceData: [],
                heartRateData: heartRateSamples,
                cadenceData: [],
                routeSegments: []
            )
        }

        let hrValues = heartRateSamples.map { $0.bpm }
        let avgHR = hrValues.isEmpty ? nil : hrValues.reduce(0, +) / Double(hrValues.count)
        let maxHR = hrValues.max()
        let minHR = hrValues.min()

        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        var elevationData: [ElevationDataPoint] = []
        var paceData: [PaceDataPoint] = []

        var cumulativeDistance: Double = 0

        for i in 1..<routeLocations.count {
            let prev = routeLocations[i - 1]
            let curr = routeLocations[i]

            let altChange = curr.altitude - prev.altitude
            if altChange > 0 {
                elevationGain += altChange
            } else {
                elevationLoss += abs(altChange)
            }

            let segmentDistance = curr.distance(from: prev)
            cumulativeDistance += segmentDistance

            if i % 10 == 0 || i == routeLocations.count - 1 {
                elevationData.append(
                    ElevationDataPoint(
                        distance: cumulativeDistance / 1000.0,
                        altitude: curr.altitude
                    ))
            }
        }

        let splits = calculateSplits(from: routeLocations)

        for split in splits {
            paceData.append(
                PaceDataPoint(
                    distance: Double(split.kilometer),
                    pace: split.pace
                ))
        }

        let routeSegments = calculateRouteSegments(from: routeLocations)

        let avgPace = totalDistance > 0 ? totalDuration / (totalDistance / 1000.0) : 0

        let speeds = routeLocations.map { $0.speed }.filter { $0 >= 0 }
        let maxSpeed = speeds.max()

        return WorkoutStatistics(
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            minHeartRate: minHR,
            elevationGain: elevationGain,
            elevationLoss: elevationLoss,
            averagePace: avgPace,
            maxSpeed: maxSpeed,
            splits: splits,
            elevationData: elevationData,
            paceData: paceData,
            heartRateData: heartRateSamples,
            cadenceData: [],
            routeSegments: routeSegments
        )
    }

    private static func calculateSplits(from locations: [CLLocation]) -> [KilometerSplit] {
        guard locations.count >= 2 else { return [] }

        var splits: [KilometerSplit] = []
        var currentKm = 1
        var kmStartIndex = 0
        var cumulativeDistance: Double = 0
        var kmStartDistance: Double = 0

        for i in 1..<locations.count {
            let prev = locations[i - 1]
            let curr = locations[i]
            let segmentDistance = curr.distance(from: prev)
            cumulativeDistance += segmentDistance

            while cumulativeDistance >= Double(currentKm) * 1000.0 {
                let kmEndTime = curr.timestamp
                let kmStartTime = locations[kmStartIndex].timestamp
                let duration = kmEndTime.timeIntervalSince(kmStartTime)

                let startAlt = locations[kmStartIndex].altitude
                let endAlt = curr.altitude
                let elevChange = endAlt - startAlt

                let distanceForSplit = cumulativeDistance - kmStartDistance
                let pace = distanceForSplit > 0 ? duration / (distanceForSplit / 1000.0) : duration

                let paceChange: TimeInterval? = splits.isEmpty ? nil : pace - splits.last!.pace

                splits.append(
                    KilometerSplit(
                        kilometer: currentKm,
                        duration: duration,
                        pace: pace,
                        paceChange: paceChange,
                        elevationChange: elevChange,
                        startLocation: locations[kmStartIndex],
                        endLocation: curr
                    ))

                kmStartIndex = i
                kmStartDistance = cumulativeDistance
                currentKm += 1
            }
        }

        let remainingDistance = cumulativeDistance - kmStartDistance
        if remainingDistance >= 100 {
            let lastLocation = locations.last!
            let startLocation = locations[kmStartIndex]
            let duration = lastLocation.timestamp.timeIntervalSince(startLocation.timestamp)
            let pace = duration / (remainingDistance / 1000.0)
            let paceChange: TimeInterval? = splits.isEmpty ? nil : pace - splits.last!.pace

            splits.append(
                KilometerSplit(
                    kilometer: currentKm,
                    duration: duration,
                    pace: pace,
                    paceChange: paceChange,
                    elevationChange: lastLocation.altitude - startLocation.altitude,
                    startLocation: startLocation,
                    endLocation: lastLocation
                ))
        }

        return splits
    }

    private static func calculateRouteSegments(from locations: [CLLocation]) -> [RouteSegment] {
        guard locations.count >= 2 else { return [] }

        // using raw coordinates without smoothing
        let finalLocations = locations

        /*
        let simplifiedLocations = RouteSmoothing.douglasPeucker(locations: locations, epsilon: 5.0)
        let smoothedLocations = RouteSmoothing.movingAverage(
            locations: simplifiedLocations, windowSize: 5)
        
        let finalLocations = RouteSmoothing.catmullRomSpline(
            locations: smoothedLocations,
            pointsPerSegment: 12,
            alpha: 0.5
        )
        */

        guard finalLocations.count >= 2 else { return [] }

        var segments: [RouteSegment] = []
        var allSpeeds: [Double] = []

        for location in locations {
            if location.speed >= 0 {
                allSpeeds.append(location.speed)
            }
        }

        if allSpeeds.isEmpty {
            for i in 1..<locations.count {
                let prev = locations[i - 1]
                let curr = locations[i]
                let distance = curr.distance(from: prev)
                let time = curr.timestamp.timeIntervalSince(prev.timestamp)
                if time > 0 && distance > 0 {
                    allSpeeds.append(distance / time)
                }
            }
        }

        guard !allSpeeds.isEmpty else { return [] }

        let minSpeed = allSpeeds.min() ?? 0
        let maxSpeed = allSpeeds.max() ?? 1
        let speedRange = maxSpeed - minSpeed

        for i in 0..<(finalLocations.count - 1) {
            let startLoc = finalLocations[i]
            let endLoc = finalLocations[i + 1]
            let coordinates = [startLoc.coordinate, endLoc.coordinate]

            var segmentSpeed: Double = 0
            if let closestOriginal = locations.min(by: {
                $0.distance(from: startLoc) < $1.distance(from: startLoc)
            }), closestOriginal.speed >= 0 {
                segmentSpeed = closestOriginal.speed
            } else {
                let distance = endLoc.distance(from: startLoc)
                let time = endLoc.timestamp.timeIntervalSince(startLoc.timestamp)
                segmentSpeed = time > 0 ? distance / time : 0
            }

            let pace = segmentSpeed > 0 ? 1000.0 / segmentSpeed : 0

            let percentile: Double
            if speedRange > 0 {
                percentile = 1.0 - ((segmentSpeed - minSpeed) / speedRange)
            } else {
                percentile = 0.5
            }

            segments.append(
                RouteSegment(
                    coordinates: coordinates,
                    pace: pace,
                    pacePercentile: max(0, min(1, percentile))
                ))
        }

        return segments
    }
}
