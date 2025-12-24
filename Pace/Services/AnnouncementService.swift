//
//  AnnouncementService.swift
//  Pace
//
//  Created by kartikay on 24/12/25.
//

import AVFoundation
import Combine
import Foundation

class AnnouncementService: ObservableObject {
    static let shared = AnnouncementService()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isMuted: Bool = false

    private var lastAnnouncedKm: Int = 0
    private var hasAnnouncedDistanceGoal: Bool = false
    private var hasAnnouncedTimeGoal: Bool = false

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AnnouncementService] Failed to setup audio session: \(error)")
        }
    }

    func reset() {
        lastAnnouncedKm = 0
        hasAnnouncedDistanceGoal = false
        hasAnnouncedTimeGoal = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speak(_ text: String) {
        guard !isMuted else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
    }

    func checkKilometerMilestone(distanceKm: Double, paceSecondsPerKm: Double) {
        let currentKm = Int(distanceKm)

        if currentKm > lastAnnouncedKm && currentKm > 0 {
            lastAnnouncedKm = currentKm

            let paceMinutes = Int(paceSecondsPerKm) / 60
            let paceSeconds = Int(paceSecondsPerKm) % 60

            let message =
                "\(currentKm) kilometer. Pace: \(paceMinutes) minutes \(paceSeconds) seconds per kilometer."
            speak(message)
        }
    }

    func checkDistanceGoal(currentKm: Double, goalKm: Double) {
        guard !hasAnnouncedDistanceGoal else { return }

        if currentKm >= goalKm {
            hasAnnouncedDistanceGoal = true
            speak("Distance goal reached! \(String(format: "%.1f", goalKm)) kilometers completed.")
        }
    }

    func checkTimeGoal(elapsedMinutes: Double, goalMinutes: Int) {
        guard !hasAnnouncedTimeGoal else { return }

        if elapsedMinutes >= Double(goalMinutes) {
            hasAnnouncedTimeGoal = true
            speak("Time goal reached! \(goalMinutes) minutes completed.")
        }
    }

    func announceWorkoutStart() {
        speak("Workout started. Good luck!")
    }

    func announceWorkoutEnd(distanceKm: Double, durationMinutes: Double) {
        let durationMin = Int(durationMinutes)
        let message =
            "Workout complete. Total distance: \(String(format: "%.2f", distanceKm)) kilometers in \(durationMin) minutes."
        speak(message)
    }
}
