# AGENT.md - Pace App Context

## Project Overview
**Pace** is an iOS fitness/walking app that displays real-time activity data with a 3D animated character companion.

## Tech Stack
- **SwiftUI** - UI framework
- **SceneKit** - 3D character rendering
- **CoreMotion** - Pedometer/step tracking
- **CoreLocation** - GPS/location services
- **MapKit** - Map display
- **HealthKitUI** - Native activity rings
- **Swift Charts** - Step history visualization

## Architecture
MVVM (Model-View-ViewModel) pattern:

```
Pace/
├── Models/              # Data structures
│   ├── StepDataPoint.swift
│   └── Activity.swift
├── ViewModels/          # Business logic + state
│   ├── HomeViewModel.swift
│   └── ActivityViewModel.swift
├── Services/            # API/SDK wrappers
│   ├── PedometerService.swift
│   ├── LocationService.swift
│   └── CharacterSceneService.swift
├── View/                # UI
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ActivityRingView.swift
│   └── Activites/
│       └── ActivitesView.swift
└── Components/          # Reusable UI components
    ├── LivePaceChart.swift
    ├── ActivityRingWrapper.swift
    └── StatRow.swift
```

## Features

### Home Screen
- 3D animated character (Walking.dae)
- Native Apple activity rings (HKActivityRingView)
- Live stats: Steps, Distance, Cadence
- Hourly step bar chart (Today's Activity)
- Light/Dark mode adaptive backgrounds

### Activities Screen
- MapKit background with user location
- Activity type selection: Walk, Run, Hike, Treadmill
- Start button with activity-colored styling
- Glass effect UI elements (.glassEffect)
- Activity picker sheet

## Key Files

| File | Purpose |
|------|---------|
| `CharacterSceneService.swift` | Loads 3D character, camera setup |
| `PedometerService.swift` | CoreMotion pedometer queries |
| `LocationService.swift` | CLLocationManager wrapper |
| `HomeViewModel.swift` | Home screen state management |
| `ActivityRingWrapper.swift` | SwiftUI wrapper for HKActivityRingView |

## Required Capabilities
- **HealthKit** - For activity rings
- **Location** - When In Use (for map)
- **Motion Usage** - For pedometer

## Info.plist Keys
```
NSLocationWhenInUseUsageDescription = "To show your location on the map"
NSMotionUsageDescription = "To track your steps and activity"
```

## Notes
- Pedometer only works on physical devices (not simulators)
- 3D character files: Walking.dae, Walking1.dae in Resources
- Theme adapts to system dark/light mode
- DONT WRITE COMMMENTS WHILE CODING
