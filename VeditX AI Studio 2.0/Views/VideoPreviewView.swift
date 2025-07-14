import SwiftUI
import AVFoundation
import AVKit

// MARK: - Video Preview View
struct VideoPreviewView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            // Preview Area
            ZStack {
                // Video Player
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            setupTimeObserver()
                        }
                        .onDisappear {
                            removeTimeObserver()
                        }
                } else {
                    // Placeholder when no video
                    Rectangle()
                        .fill(Color.black)
                        .overlay(
                            VStack(spacing: 16) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No video loaded")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("Add media to timeline to preview")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        )
                }
                
                // Subtitle overlay
                if !getCurrentSubtitles().isEmpty {
                    VStack {
                        Spacer()
                        ForEach(getCurrentSubtitles()) { subtitle in
                            Text(subtitle.text)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.7))
                                )
                        }
                        .padding(.bottom, 40)
                    }
                }
                
                // Loading indicator
                if viewModel.isPlaying && player?.currentItem == nil {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onChange(of: viewModel.currentProject.timeline.tracks) { _ in
                updateVideoPlayer()
            }
            .onChange(of: viewModel.playbackTime) { newTime in
                seekPlayer(to: newTime)
            }
            
            // Playback Controls
            PlaybackControlsView(viewModel: viewModel)
        }
        .padding()
        .glassEffect(cornerRadius: 12, material: .hudWindow)
        .onAppear {
            updateVideoPlayer()
        }
        .onDisappear {
            removeTimeObserver()
            player?.pause()
        }
    }
    
    private func getCurrentSubtitles() -> [Subtitle] {
        return viewModel.currentProject.subtitles.filter { subtitle in
            viewModel.playbackTime >= subtitle.startTime && 
            viewModel.playbackTime <= subtitle.endTime
        }
    }
    
    private func updateVideoPlayer() {
        // Find the first video clip at current time
        let currentClips = viewModel.currentProject.timeline.getClips(at: viewModel.playbackTime)
        let videoClip = currentClips.first { $0.mediaItem.type == .video }
        
        if let videoClip = videoClip {
            // Create player for video clip
            let playerItem = AVPlayerItem(url: videoClip.mediaItem.url)
            player = AVPlayer(playerItem: playerItem)
            
            // Seek to correct position within the clip
            let clipTime = viewModel.playbackTime - videoClip.startTime + videoClip.trimStart
            let cmTime = CMTime(seconds: clipTime, preferredTimescale: 600)
            player?.seek(to: cmTime)
            
            // Sync playback state
            if viewModel.isPlaying {
                player?.play()
            }
        } else {
            // No video clip, show placeholder
            player?.pause()
            player = nil
        }
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 1.0/30.0, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            // Update viewModel playback time based on player progress
            // This creates a feedback loop, so we need to be careful
            if viewModel.isPlaying {
                let currentTime = CMTimeGetSeconds(time)
                // Update only if there's a significant difference to avoid feedback loops
                if abs(currentTime - viewModel.playbackTime) > 0.1 {
                    viewModel.playbackTime = currentTime
                }
            }
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    private func seekPlayer(to time: TimeInterval) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
}

// MARK: - Playback Controls View
struct PlaybackControlsView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Timeline scrubber
            HStack {
                Text(viewModel.playbackTime.formattedTime)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondaryText)
                    .frame(width: 60, alignment: .leading)
                
                TimelineSlider(
                    value: Binding(
                        get: { viewModel.playbackTime },
                        set: { viewModel.seekTo(time: $0) }
                    ),
                    range: 0...max(viewModel.currentProject.timeline.duration, 1)
                )
                
                Text(viewModel.currentProject.timeline.duration.formattedTime)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondaryText)
                    .frame(width: 60, alignment: .trailing)
            }
            
            // Control buttons
            HStack(spacing: 30) {
                // Previous/Skip backward
                Button(action: {
                    viewModel.seekTo(time: max(0, viewModel.playbackTime - 5))
                }) {
                    Image(systemName: "gobackward.5")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .help("Skip backward 5s")
                
                // Play/Pause
                Button(action: {
                    viewModel.togglePlayback()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentOrange)
                .help(viewModel.isPlaying ? "Pause" : "Play")
                
                // Next/Skip forward
                Button(action: {
                    viewModel.seekTo(time: min(viewModel.currentProject.timeline.duration, viewModel.playbackTime + 5))
                }) {
                    Image(systemName: "goforward.5")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .help("Skip forward 5s")
                
                Spacer()
                
                // Volume control
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Slider(value: .constant(0.8), in: 0...1)
                        .frame(width: 60)
                        .accentColor(.accentBlue)
                }
                
                // Fullscreen button
                Button(action: {
                    // TODO: Implement fullscreen
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondaryText)
                .help("Fullscreen")
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Custom Timeline Slider
struct TimelineSlider: View {
    @Binding var value: TimeInterval
    let range: ClosedRange<TimeInterval>
    @State private var isEditing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                // Progress
                Rectangle()
                    .fill(Color.accentOrange)
                    .frame(width: progressWidth(in: geometry), height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                // Thumb
                Circle()
                    .fill(Color.accentOrange)
                    .frame(width: isEditing ? 16 : 12, height: isEditing ? 16 : 12)
                    .offset(x: progressWidth(in: geometry) - (isEditing ? 8 : 6))
                    .animation(.easeInOut(duration: 0.1), value: isEditing)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        withAnimation(.none) {
                            isEditing = true
                            let progress = gesture.location.x / geometry.size.width
                            let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * progress
                            value = max(range.lowerBound, min(range.upperBound, newValue))
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isEditing = false
                        }
                    }
            )
        }
        .frame(height: 20)
    }
    
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return geometry.size.width * progress
    }
}

#Preview {
    VideoPreviewView(viewModel: MainViewModel())
        .frame(width: 600, height: 400)
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
} 