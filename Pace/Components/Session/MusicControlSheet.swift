//
//  MusicControlSheet.swift
//  Pace
//
//  Created by kartikay on 23/12/25.
//

import SwiftUI

struct MusicControlSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var musicService: MusicService
    
    
    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0
    
    private var displayProgress: Double {
        isScrubbing ? scrubValue : musicService.progress
    }
    
    private var displayTime: TimeInterval {
        isScrubbing ? scrubValue * musicService.duration : musicService.currentPlaybackTime
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            if musicService.hasNowPlaying {
                nowPlayingView
            } else {
                emptyStateView
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
    
    
    
    private var nowPlayingView: some View {
        VStack(spacing: 16) {
            
            Group {
                if let artwork = musicService.nowPlayingArtwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color(.systemGray5)
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            
            
            VStack(spacing: 2) {
                Text(musicService.nowPlayingTitle ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(musicService.nowPlayingArtist ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(height: 4)
                        
                        
                        Capsule()
                            .fill(Color.primary)
                            .frame(width: max(0, geometry.size.width * displayProgress), height: 4)
                        
                        
                        Circle()
                            .fill(Color.primary)
                            .frame(width: isScrubbing ? 16 : 12, height: isScrubbing ? 16 : 12)
                            .offset(x: max(0, min(geometry.size.width - 12, geometry.size.width * displayProgress - 6)))
                            .animation(.easeOut(duration: 0.1), value: isScrubbing)
                    }
                    .frame(height: 20)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isScrubbing {
                                    isScrubbing = true
                                    scrubValue = musicService.progress
                                }
                                let newValue = value.location.x / geometry.size.width
                                scrubValue = max(0, min(1, newValue))
                            }
                            .onEnded { _ in
                                musicService.seek(to: scrubValue)
                                isScrubbing = false
                            }
                    )
                }
                .frame(height: 20)
                
                HStack {
                    Text(musicService.formatTime(displayTime))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(musicService.formatTime(musicService.duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            
            
            HStack(spacing: 50) {
                Button {
                    musicService.previous()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                
                Button {
                    musicService.togglePlayPause()
                } label: {
                    Image(systemName: musicService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                
                Button {
                    musicService.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: musicService.isPlaying)
        }
    }
    
    
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "music.note")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            
            Text("No Music Playing")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Open your music app to start\nplaying something")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                musicService.openMusicApp()
            } label: {
                Label("Open Apple Music", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            MusicControlSheet(musicService: MusicService())
        }
}
