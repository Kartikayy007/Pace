//
//  WorkoutDetailData.swift
//  Pace
//
//  Created by kartikay on 22/12/25.
//


import CoreLocation
import Foundation



struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
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
                elevationData.append(ElevationDataPoint(
                    distance: cumulativeDistance / 1000.0,
                    altitude: curr.altitude
                ))
            }
        }
        
        
        let splits = calculateSplits(from: routeLocations)
        
        
        for split in splits {
            paceData.append(PaceDataPoint(
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
                
                splits.append(KilometerSplit(
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
            
            splits.append(KilometerSplit(
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
        
        
        let segmentSize = 2
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
        
        
        var i = 0
        while i < locations.count - 1 {
            let endIndex = min(i + segmentSize, locations.count - 1)
            let segmentLocations = Array(locations[i...endIndex])
            let coordinates = segmentLocations.map { $0.coordinate }
            
            
            var segmentSpeed: Double = 0
            var validSpeedCount = 0
            for loc in segmentLocations {
                if loc.speed >= 0 {
                    segmentSpeed += loc.speed
                    validSpeedCount += 1
                }
            }
            
            if validSpeedCount > 0 {
                segmentSpeed /= Double(validSpeedCount)
            } else {
                
                let distance = segmentLocations.last!.distance(from: segmentLocations.first!)
                let time = segmentLocations.last!.timestamp.timeIntervalSince(segmentLocations.first!.timestamp)
                segmentSpeed = time > 0 ? distance / time : 0
            }
            
            
            let pace = segmentSpeed > 0 ? 1000.0 / segmentSpeed : 0
            
            
            
            let percentile: Double
            if speedRange > 0 {
                percentile = 1.0 - ((segmentSpeed - minSpeed) / speedRange)
            } else {
                percentile = 0.5
            }
            
            segments.append(RouteSegment(
                coordinates: coordinates,
                pace: pace,
                pacePercentile: max(0, min(1, percentile)) 
            ))
            
            i = endIndex
        }
        
        return segments
    }
}
