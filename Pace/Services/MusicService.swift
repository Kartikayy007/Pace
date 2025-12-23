//
//  MusicService.swift
//  Pace
//
//  Created by kartikay on 23/12/25.
//

import Foundation
import MediaPlayer
import UIKit

@Observable
class MusicService {
    // MARK: - Now Playing Info
    var nowPlayingTitle: String?
    var nowPlayingArtist: String?
    var nowPlayingAlbum: String?
    var nowPlayingArtwork: UIImage?
    var isPlaying: Bool = false
    
    // MARK: - Playback Progress
    var currentPlaybackTime: TimeInterval = 0
    var duration: TimeInterval = 0
    
    var progress: Double {
        get {
            guard duration > 0 else { return 0 }
            return currentPlaybackTime / duration
        }
        set {
            seek(to: newValue)
        }
    }
    
    var hasNowPlaying: Bool {
        nowPlayingTitle != nil
    }
    
    // MARK: - Private
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var progressTimer: Timer?
    private var lastKnownTitle: String?
    private var cachedArtwork: UIImage?
    
    init() {
        setupNotifications()
        updateNowPlayingInfo()
        startProgressTimer()
    }
    
    deinit {
        progressTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        musicPlayer.endGeneratingPlaybackNotifications()
    }
    
    // MARK: - Playback Controls
    
    func play() {
        musicPlayer.play()
        isPlaying = true
    }
    
    func pause() {
        musicPlayer.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func next() {
        musicPlayer.skipToNextItem()
    }
    
    func previous() {
        if musicPlayer.currentPlaybackTime > 3 {
            musicPlayer.skipToBeginning()
        } else {
            musicPlayer.skipToPreviousItem()
        }
    }
    
    func seek(to progress: Double) {
        let newTime = duration * max(0, min(1, progress))
        musicPlayer.currentPlaybackTime = newTime
        currentPlaybackTime = newTime
    }
    
    func openMusicApp() {
        if let url = URL(string: "music://") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        let nc = NotificationCenter.default
        
        nc.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )
        
        nc.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    @objc private func nowPlayingItemChanged() {
        updateNowPlayingInfo()
    }
    
    @objc private func playbackStateChanged() {
        isPlaying = musicPlayer.playbackState == .playing
    }
    
    private func updateNowPlayingInfo() {
        // Try Apple Music player first
        if let item = musicPlayer.nowPlayingItem {
            let title = item.title
            
            // Only update artwork if song changed (prevents flickering)
            if title != lastKnownTitle {
                lastKnownTitle = title
                nowPlayingTitle = title
                nowPlayingArtist = item.artist
                nowPlayingAlbum = item.albumTitle
                duration = item.playbackDuration
                
                // Update artwork only on song change
                if let artwork = item.artwork {
                    let size = CGSize(width: 300, height: 300)
                    cachedArtwork = artwork.image(at: size)
                    nowPlayingArtwork = cachedArtwork
                } else {
                    cachedArtwork = nil
                    nowPlayingArtwork = nil
                }
            }
            
            currentPlaybackTime = musicPlayer.currentPlaybackTime
            isPlaying = musicPlayer.playbackState == .playing
            return
        }
        
        // Fallback: Try MPNowPlayingInfoCenter (other apps like Spotify)
        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        if let info = nowPlayingInfo, !info.isEmpty {
            let title = info[MPMediaItemPropertyTitle] as? String
            
            // Only update artwork if song changed
            if title != lastKnownTitle {
                lastKnownTitle = title
                nowPlayingTitle = title
                nowPlayingArtist = info[MPMediaItemPropertyArtist] as? String
                nowPlayingAlbum = info[MPMediaItemPropertyAlbumTitle] as? String
                duration = info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval ?? 0
                
                if let artworkData = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
                    cachedArtwork = artworkData.image(at: CGSize(width: 300, height: 300))
                    nowPlayingArtwork = cachedArtwork
                } else {
                    cachedArtwork = nil
                    nowPlayingArtwork = nil
                }
            }
            
            currentPlaybackTime = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval ?? 0
            let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
            isPlaying = playbackRate > 0
            return
        }
        
        // Nothing playing - clear everything
        if lastKnownTitle != nil {
            lastKnownTitle = nil
            nowPlayingTitle = nil
            nowPlayingArtist = nil
            nowPlayingAlbum = nil
            nowPlayingArtwork = nil
            cachedArtwork = nil
            duration = 0
            currentPlaybackTime = 0
            isPlaying = false
        }
    }
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Update playback time
            if self.musicPlayer.nowPlayingItem != nil {
                self.currentPlaybackTime = self.musicPlayer.currentPlaybackTime
                self.isPlaying = self.musicPlayer.playbackState == .playing
            } else if let info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                self.currentPlaybackTime = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval ?? 0
                let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
                self.isPlaying = playbackRate > 0
            }
            
            // Check if song changed
            let currentTitle = self.musicPlayer.nowPlayingItem?.title 
                ?? MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
            
            if currentTitle != self.lastKnownTitle {
                self.updateNowPlayingInfo()
            }
        }
    }
    
    // MARK: - Time Formatting
    
    func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
