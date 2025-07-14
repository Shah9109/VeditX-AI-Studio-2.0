import SwiftUI
import UniformTypeIdentifiers

struct TimelineEditorView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var draggedClip: TimelineClip?
    @State private var trackHeight: CGFloat = 80
    @State private var timelineScale: CGFloat = 1.0
    @State private var playheadPosition: CGFloat = 0
    @State private var showingTrackMenu = false
    @State private var selectedTrack: TimelineTrack?
    @State private var showingEffectsPanel = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Timeline Header
            TimelineHeaderView(
                viewModel: viewModel,
                scale: $timelineScale,
                showingTrackMenu: $showingTrackMenu,
                showingEffectsPanel: $showingEffectsPanel
            )
            
            HStack(spacing: 0) {
                // Track Controls Panel
                TrackControlsPanel(
                    viewModel: viewModel,
                    trackHeight: trackHeight,
                    selectedTrack: $selectedTrack
                )
                .frame(width: 200)
                
                // Timeline Content
                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 2) {
                        ForEach(viewModel.currentProject.timeline.tracks.indices, id: \.self) { index in
                            let track = viewModel.currentProject.timeline.tracks[index]
                            EnhancedTimelineTrackView(
                                track: track,
                                trackIndex: index,
                                viewModel: viewModel,
                                trackHeight: trackHeight,
                                scale: timelineScale,
                                draggedClip: $draggedClip,
                                playheadPosition: playheadPosition,
                                selectedTrack: $selectedTrack
                            )
                        }
                        
                        // Add Track Button
                        AddTrackButtonView(viewModel: viewModel, trackHeight: trackHeight)
                    }
                    .padding(.horizontal, 12)
                }
                .overlay(
                    // Enhanced Playhead
                    PlayheadView(
                        position: playheadPosition,
                        trackCount: viewModel.currentProject.timeline.tracks.count,
                        trackHeight: trackHeight
                    )
                )
                .onReceive(viewModel.$playbackTime) { time in
                    withAnimation(.linear(duration: 0.1)) {
                        playheadPosition = CGFloat(time * 10 * timelineScale)
                    }
                }
            }
        }
        .glassEffect(cornerRadius: 12, material: .hudWindow)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleTimelineDrop(providers: providers)
        }
        .sheet(isPresented: $showingTrackMenu) {
            TrackManagementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEffectsPanel) {
            if let track = selectedTrack {
                EffectsPanel(track: track, viewModel: viewModel)
            }
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

// MARK: - Enhanced Timeline Header
struct TimelineHeaderView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var scale: CGFloat
    @Binding var showingTrackMenu: Bool
    @Binding var showingEffectsPanel: Bool
    
    var body: some View {
        HStack {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Spacer()
            
            HStack(spacing: 12) {
                // Track Management
                Button(action: { showingTrackMenu = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                        Text("Tracks")
                    }
                    .font(.caption)
                    .foregroundColor(.accentBlue)
                }
                .buttonStyle(.plain)
                
                // Effects Panel
                Button(action: { showingEffectsPanel = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Effects")
                    }
                    .font(.caption)
                    .foregroundColor(.accentPurple)
                }
                .buttonStyle(.plain)
                
                Divider()
                    .frame(height: 20)
                
                // Zoom Controls
                Button(action: { scale = max(0.5, scale - 0.25) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundColor(.secondaryText)
                }
                
                Text("\(Int(scale * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 40)
                
                Button(action: { scale = min(3.0, scale + 0.25) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundColor(.secondaryText)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Playback Controls
                Button(action: viewModel.togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.accentBlue)
                }
                
                Button(action: viewModel.stopPlayback) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.accentOrange)
                }
                
                // Time Display
                Text(formatTime(viewModel.playbackTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .frame(width: 60, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let frames = Int((time.truncatingRemainder(dividingBy: 1)) * 30)
        return String(format: "%02d:%02d:%02d", minutes, seconds, frames)
    }
}

// MARK: - Track Controls Panel
struct TrackControlsPanel: View {
    @ObservedObject var viewModel: MainViewModel
    let trackHeight: CGFloat
    @Binding var selectedTrack: TimelineTrack?
    
    var body: some View {
        VStack(spacing: 2) {
            // Header
            HStack {
                Text("Tracks")
                    .font(.caption.bold())
                    .foregroundColor(.primaryText)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
            
            // Track Controls
            ForEach(viewModel.currentProject.timeline.tracks.indices, id: \.self) { index in
                let track = viewModel.currentProject.timeline.tracks[index]
                TrackControlView(
                    track: track,
                    trackHeight: trackHeight,
                    isSelected: selectedTrack?.id == track.id,
                    onSelect: { selectedTrack = track },
                    onDelete: { viewModel.removeTrack(track.id) }
                )
            }
            
            Spacer()
        }
        .background(Color.black.opacity(0.1))
    }
}

// MARK: - Track Control View
struct TrackControlView: View {
    @ObservedObject var track: TimelineTrack
    let trackHeight: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                // Track Icon
                Image(systemName: track.type.icon)
                    .foregroundColor(track.type.color)
                    .frame(width: 16)
                
                // Track Name
                Text(track.name)
                    .font(.caption)
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                // Track Controls
                HStack(spacing: 4) {
                    // Visibility Toggle
                    Button(action: { track.isVisible.toggle() }) {
                        Image(systemName: track.isVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(track.isVisible ? .accentBlue : .secondaryText)
                            .font(.caption)
                    }
                    
                    // Lock Toggle
                    Button(action: { track.isLocked.toggle() }) {
                        Image(systemName: track.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(track.isLocked ? .accentOrange : .secondaryText)
                            .font(.caption)
                    }
                    
                    // Mute Toggle
                    if track.type == .audio || track.type == .video {
                        Button(action: { track.isMuted.toggle() }) {
                            Image(systemName: track.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundColor(track.isMuted ? .red : .secondaryText)
                                .font(.caption)
                        }
                    }
                    
                    // Delete Track
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            // Volume/Opacity Controls
            if track.type == .audio || track.type == .video {
                HStack(spacing: 4) {
                    Image(systemName: track.type == .audio ? "speaker.wave.1" : "opacity")
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                    
                    Slider(
                        value: track.type == .audio ? 
                            Binding(get: { track.volume }, set: { track.volume = $0 }) :
                            Binding(get: { track.opacity }, set: { track.opacity = $0 }),
                        in: 0...1
                    )
                    .tint(track.type.color)
                    
                    Text("\(Int((track.type == .audio ? track.volume : track.opacity) * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                        .frame(width: 30)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: trackHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? track.type.color.opacity(0.2) : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Enhanced Timeline Track View
struct EnhancedTimelineTrackView: View {
    @ObservedObject var track: TimelineTrack
    let trackIndex: Int
    @ObservedObject var viewModel: MainViewModel
    let trackHeight: CGFloat
    let scale: CGFloat
    @Binding var draggedClip: TimelineClip?
    let playheadPosition: CGFloat
    @Binding var selectedTrack: TimelineTrack?
    
    var body: some View {
        HStack(spacing: 0) {
            // Track Content Area
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(height: trackHeight)
                
                // Multiple video layers support
                ForEach(track.clips.indices, id: \.self) { clipIndex in
                    let clip = track.clips[clipIndex]
                    EnhancedTimelineClipView(
                        clip: clip,
                        clipIndex: clipIndex,
                        viewModel: viewModel,
                        scale: scale,
                        draggedClip: $draggedClip
                    )
                    .position(
                        x: CGFloat(clip.startTime * 10 * scale) + (CGFloat(clip.duration * 10 * scale) / 2),
                        y: trackHeight / 2 + CGFloat(clip.layerIndex * 5) // Layer offset
                    )
                }
                
                // Track Effects Indicator
                if !track.effects.isEmpty {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.accentPurple)
                            Text("\(track.effects.count)")
                                .font(.caption2)
                                .foregroundColor(.accentPurple)
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        .padding(.trailing, 8)
                        Spacer()
                    }
                    .frame(height: trackHeight)
                }
            }
            .frame(minWidth: 1000)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onDrop(of: [.text], isTargeted: nil) { providers in
                handleClipDrop(providers: providers)
            }
            .onTapGesture {
                selectedTrack = track
            }
        }
    }
    
    private func handleClipDrop(providers: [NSItemProvider]) -> Bool {
        // Handle clip reordering and external media drops
        return true
    }
}

// MARK: - Enhanced Timeline Clip View
struct EnhancedTimelineClipView: View {
    let clip: TimelineClip
    let clipIndex: Int
    @ObservedObject var viewModel: MainViewModel
    let scale: CGFloat
    @Binding var draggedClip: TimelineClip?
    @State private var isSelected = false
    @State private var showingClipEditor = false
    
    var clipColor: Color {
        switch clip.mediaItem.type {
        case .video: return .timelineVideo
        case .audio: return .timelineAudio
        case .image: return .timelineImage
        }
    }
    
    var body: some View {
        clipMainBody
        .onTapGesture {
            isSelected.toggle()
            if isSelected {
                viewModel.selectedTimelineClips.insert(clip.id)
            } else {
                viewModel.selectedTimelineClips.remove(clip.id)
            }
        }
        .onTapGesture(count: 2) {
            showingClipEditor = true
        }
        .draggable(clip.id.uuidString) {
            clipDragPreview
        }
        .sheet(isPresented: $showingClipEditor) {
            ClipEditorView(clip: clip, viewModel: viewModel)
        }
    }
    
    private var clipMainBody: some View {
        VStack(spacing: 0) {
            clipRectangle
            clipVolumeIndicator
        }
    }
    
    private var clipRectangle: some View {
        Rectangle()
            .fill(clipColor.opacity(isSelected ? 1.0 : 0.8))
            .frame(width: CGFloat(clip.duration * 10 * scale), height: 50 - CGFloat(clip.layerIndex * 2))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(clipOverlayContent)
            .overlay(clipSelectionBorder)
            .scaleEffect(draggedClip?.id == clip.id ? 1.05 : 1.0)
    }
    
    private var clipOverlayContent: some View {
        HStack {
            clipInfoSection
            Spacer()
            clipTrimIndicator
        }
        .padding(4)
    }
    
    private var clipInfoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(clip.mediaItem.name)
                .font(.caption2)
                .foregroundColor(.white)
                .truncationMode(.tail)
                .lineLimit(1)
            
            clipMetadataRow
        }
    }
    
    private var clipMetadataRow: some View {
        HStack(spacing: 4) {
            Text(String(format: "%.1fs", clip.duration))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            if clip.speed != 1.0 {
                Text("\(clip.speed, specifier: "%.1f")x")
                    .font(.caption2)
                    .foregroundColor(.accentOrange)
            }
            
            if !clip.effects.isEmpty {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(.accentPurple)
            }
        }
    }
    
    @ViewBuilder
    private var clipTrimIndicator: some View {
        if clip.trimStart > 0 || clip.trimEnd > 0 {
            Image(systemName: "scissors")
                .font(.caption2)
                .foregroundColor(.accentOrange)
        }
    }
    
    private var clipSelectionBorder: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(isSelected ? Color.accentBlue : Color.clear, lineWidth: 2)
    }
    
    @ViewBuilder
    private var clipVolumeIndicator: some View {
        if clip.volume != 1.0 || clip.opacity != 1.0 {
            Rectangle()
                .fill(Color.accentBlue.opacity(0.3))
                .frame(height: 2)
                .frame(width: CGFloat(clip.duration * 10 * scale) * CGFloat(max(clip.volume, clip.opacity)))
        }
    }
    
    private var clipDragPreview: some View {
        Rectangle()
            .fill(clipColor.opacity(0.6))
            .frame(width: 60, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Enhanced Add Track Button
struct AddTrackButtonView: View {
    @ObservedObject var viewModel: MainViewModel
    let trackHeight: CGFloat
    @State private var showingTrackTypeMenu = false
    
    var body: some View {
        Menu {
            ForEach(TimelineTrack.TrackType.allCases, id: \.self) { trackType in
                Button(action: {
                    viewModel.addTrack(type: trackType)
                }) {
                    HStack {
                        Image(systemName: trackType.icon)
                        Text(trackType.rawValue)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentBlue)
                Text("Add Track")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
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

// MARK: - Enhanced Playhead
struct PlayheadView: View {
    let position: CGFloat
    let trackCount: Int
    let trackHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Playhead handle
            Triangle()
                .fill(Color.red)
                .frame(width: 12, height: 8)
            
            // Playhead line
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: CGFloat(trackCount) * (trackHeight + 2))
        }
        .position(x: position + 200, y: CGFloat(trackCount) * (trackHeight + 2) / 2 + 8)
        .allowsHitTesting(false)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

#Preview {
    TimelineEditorView(viewModel: MainViewModel())
        .frame(height: 400)
} 