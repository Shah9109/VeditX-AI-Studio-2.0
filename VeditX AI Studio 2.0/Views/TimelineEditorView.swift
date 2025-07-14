import SwiftUI
import UniformTypeIdentifiers

struct TimelineEditorView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var draggedClip: TimelineClip?
    @State private var trackHeight: CGFloat = 60
    @State private var timelineScale: CGFloat = 1.0
    @State private var playheadPosition: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Timeline Header
            TimelineHeaderView(viewModel: viewModel, scale: $timelineScale)
            
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 4) {
                    ForEach(viewModel.currentProject.timeline.tracks) { track in
                        TimelineTrackRowView(
                            track: track,
                            viewModel: viewModel,
                            trackHeight: trackHeight,
                            scale: timelineScale,
                            draggedClip: $draggedClip,
                            playheadPosition: playheadPosition
                        )
                    }
                    
                    // Add Track Button
                    AddTrackButtonView(viewModel: viewModel, trackHeight: trackHeight)
                }
                .padding(.horizontal, 12)
            }
            .overlay(
                // Playhead Indicator
                PlayheadView(position: playheadPosition, trackCount: viewModel.currentProject.timeline.tracks.count, trackHeight: trackHeight)
            )
            .onReceive(viewModel.$playbackTime) { time in
                withAnimation(.linear(duration: 0.1)) {
                    playheadPosition = CGFloat(time * 10 * timelineScale) // 10 pixels per second
                }
            }
        }
        .glassEffect(cornerRadius: 12, material: .hudWindow)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleTimelineDrop(providers: providers)
        }
    }
    
    private func handleTimelineDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                DispatchQueue.main.async {
                    viewModel.addMediaToTimeline(url: url, at: viewModel.playbackTime)
                }
            }
        }
        return true
    }
}

struct TimelineHeaderView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var scale: CGFloat
    
    var body: some View {
        HStack {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            HStack(spacing: 12) {
                // Zoom Controls
                Button(action: { scale = max(0.5, scale - 0.25) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundColor(.secondaryText)
                }
                
                Button(action: { scale = min(3.0, scale + 0.25) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundColor(.secondaryText)
                }
                
                // Playback Controls
                Button(action: viewModel.togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.accentBlue)
                }
                
                Button(action: viewModel.stopPlayback) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.accentOrange)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
    }
}

struct TimelineTrackRowView: View {
    let track: TimelineTrack
    @ObservedObject var viewModel: MainViewModel
    let trackHeight: CGFloat
    let scale: CGFloat
    @Binding var draggedClip: TimelineClip?
    let playheadPosition: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            // Track Label
            Text(track.name)
                .font(.caption)
                .foregroundColor(.secondaryText)
                .frame(width: 100, alignment: .leading)
                .padding(.leading, 8)
            
            // Track Content Area
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(height: trackHeight)
                
                // Timeline Clips
                ForEach(track.clips) { clip in
                    TimelineClipView(
                        clip: clip,
                        viewModel: viewModel,
                        scale: scale,
                        draggedClip: $draggedClip
                    )
                    .position(
                        x: CGFloat(clip.startTime * 10 * scale) + (CGFloat(clip.duration * 10 * scale) / 2),
                        y: trackHeight / 2
                    )
                }
            }
            .frame(minWidth: 800)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleClipDrop(providers: providers, track: track)
            }
        }
    }
    
    private func handleClipDrop(providers: [NSItemProvider], track: TimelineTrack) -> Bool {
        // Handle internal clip reordering and external media drops
        return true
    }
}

struct TimelineClipView: View {
    let clip: TimelineClip
    @ObservedObject var viewModel: MainViewModel
    let scale: CGFloat
    @Binding var draggedClip: TimelineClip?
    @State private var isSelected = false
    
    var clipColor: Color {
        switch clip.mediaItem.type {
        case .video: return .timelineVideo
        case .audio: return .timelineAudio
        case .image: return .timelineImage
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(clipColor.opacity(isSelected ? 1.0 : 0.8))
            .frame(width: CGFloat(clip.duration * 10 * scale), height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                VStack {
                    Text(clip.mediaItem.name)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .truncationMode(.tail)
                        .lineLimit(1)
                    
                    Text(String(format: "%.1fs", clip.duration))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.accentBlue : Color.clear, lineWidth: 2)
            )
            .scaleEffect(draggedClip?.id == clip.id ? 1.05 : 1.0)
            .onTapGesture {
                isSelected.toggle()
                if isSelected {
                    viewModel.selectedTimelineClips.insert(clip.id)
                } else {
                    viewModel.selectedTimelineClips.remove(clip.id)
                }
            }
            .draggable(clip.id.uuidString) {
                Rectangle()
                    .fill(clipColor.opacity(0.6))
                    .frame(width: 60, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
    }
}

struct AddTrackButtonView: View {
    @ObservedObject var viewModel: MainViewModel
    let trackHeight: CGFloat
    
    var body: some View {
        Button(action: {
            viewModel.addNewTrack()
        }) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentBlue)
                Text("Add Track")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                Spacer()
            }
            .frame(height: trackHeight)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct PlayheadView: View {
    let position: CGFloat
    let trackCount: Int
    let trackHeight: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 2, height: CGFloat(trackCount) * (trackHeight + 4))
            .position(x: position + 100, y: CGFloat(trackCount) * (trackHeight + 4) / 2)
            .allowsHitTesting(false)
    }
}

#Preview {
    TimelineEditorView(viewModel: MainViewModel())
        .frame(height: 300)
} 