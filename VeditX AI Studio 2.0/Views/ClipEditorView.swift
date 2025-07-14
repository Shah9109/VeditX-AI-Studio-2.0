import SwiftUI
import AVFoundation

struct ClipEditorView: View {
    let clip: TimelineClip
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: EditorTab = .transform
    @State private var previewTime: TimeInterval = 0
    
    enum EditorTab: String, CaseIterable {
        case transform = "Transform"
        case effects = "Effects"
        case audio = "Audio"
        case speed = "Speed & Time"
        
        var icon: String {
            switch self {
            case .transform: return "crop.rotate"
            case .effects: return "sparkles"
            case .audio: return "waveform"
            case .speed: return "speedometer"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            ClipEditorHeader(clip: clip, onDismiss: { dismiss() })
            
            HStack(spacing: 16) {
                // Video Preview
                ClipPreviewView(
                    clip: clip,
                    viewModel: viewModel,
                    previewTime: $previewTime
                )
                .frame(width: 400, height: 300)
                
                // Editor Controls
                VStack(alignment: .leading, spacing: 16) {
                    // Tab Selector
                    TabSelectorView(selectedTab: $selectedTab)
                    
                    // Editor Content
                    ScrollView {
                        switch selectedTab {
                        case .transform:
                            TransformEditorView(clip: clip)
                        case .effects:
                            ClipEffectsView(clip: clip)
                        case .audio:
                            AudioEditorView(clip: clip)
                        case .speed:
                            SpeedEditorView(clip: clip)
                        }
                    }
                }
                .frame(width: 350)
            }
            
            // Timeline Scrubber
            ClipTimelineView(clip: clip, previewTime: $previewTime)
            
            // Action Buttons
            HStack {
                Button("Reset") {
                    resetClip()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Apply") {
                    applyChanges()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 800, height: 600)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
    
    private func resetClip() {
        // Reset clip properties to default
    }
    
    private func applyChanges() {
        // Apply changes to the actual clip
    }
}

// MARK: - Clip Editor Header
struct ClipEditorHeader: View {
    let clip: TimelineClip
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Clip Editor")
                    .font(.title2.bold())
                    .foregroundColor(.primaryText)
                
                Text(clip.mediaItem.name)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentBlue)
        }
    }
}

// MARK: - Tab Selector
struct TabSelectorView: View {
    @Binding var selectedTab: ClipEditorView.EditorTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ClipEditorView.EditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTab == tab ? Color.accentBlue : Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

// MARK: - Clip Preview
struct ClipPreviewView: View {
    let clip: TimelineClip
    @ObservedObject var viewModel: MainViewModel
    @Binding var previewTime: TimeInterval
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // Video Player
            if let player = player {
                Rectangle()
                    .fill(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Text("Video Preview")
                            .foregroundColor(.white)
                            .opacity(0.7)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        VStack {
                            Image(systemName: "video.slash")
                                .font(.title)
                                .foregroundColor(.secondaryText)
                            Text("No Preview Available")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                    )
            }
            
            // Transform Overlay
            TransformOverlayView(clip: clip)
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        if clip.mediaItem.type == .video {
            player = AVPlayer(url: clip.mediaItem.url)
        }
    }
}

// MARK: - Transform Overlay
struct TransformOverlayView: View {
    let clip: TimelineClip
    
    var body: some View {
        GeometryReader { geometry in
            // Crop rectangle overlay
            if let cropRect = clip.transform.cropRect {
                Rectangle()
                    .stroke(Color.accentBlue, lineWidth: 2)
                    .frame(
                        width: cropRect.width * geometry.size.width,
                        height: cropRect.height * geometry.size.height
                    )
                    .position(
                        x: cropRect.midX * geometry.size.width,
                        y: cropRect.midY * geometry.size.height
                    )
            }
            
            // Corner handles for cropping
            if clip.transform.cropRect != nil {
                ForEach(0..<4) { index in
                    CropHandle(index: index, clip: clip, geometry: geometry)
                }
            }
        }
    }
}

// MARK: - Crop Handle
struct CropHandle: View {
    let index: Int
    let clip: TimelineClip
    let geometry: GeometryProxy
    
    var body: some View {
        Circle()
            .fill(Color.accentBlue)
            .frame(width: 12, height: 12)
            .position(handlePosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update crop rectangle based on handle drag
                    }
            )
    }
    
    private var handlePosition: CGPoint {
        guard let cropRect = clip.transform.cropRect else { return .zero }
        
        switch index {
        case 0: return CGPoint(x: cropRect.minX * geometry.size.width, y: cropRect.minY * geometry.size.height)
        case 1: return CGPoint(x: cropRect.maxX * geometry.size.width, y: cropRect.minY * geometry.size.height)
        case 2: return CGPoint(x: cropRect.maxX * geometry.size.width, y: cropRect.maxY * geometry.size.height)
        case 3: return CGPoint(x: cropRect.minX * geometry.size.width, y: cropRect.maxY * geometry.size.height)
        default: return .zero
        }
    }
}

// MARK: - Transform Editor
struct TransformEditorView: View {
    let clip: TimelineClip
    @State private var position: CGSize
    @State private var scale: CGSize
    @State private var rotation: Double
    @State private var cropEnabled: Bool = false
    
    init(clip: TimelineClip) {
        self.clip = clip
        self._position = State(initialValue: CGSize(width: clip.transform.position.x, height: clip.transform.position.y))
        self._scale = State(initialValue: clip.transform.scale)
        self._rotation = State(initialValue: clip.transform.rotation)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transform")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Position Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Position")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text("X:")
                        .font(.caption)
                        .frame(width: 20, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { position.width },
                        set: { position.width = $0 }
                    ), in: -1...1)
                    .tint(.accentBlue)
                    
                    Text("\(Int(position.width * 100))")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                HStack {
                    Text("Y:")
                        .font(.caption)
                        .frame(width: 20, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { position.height },
                        set: { position.height = $0 }
                    ), in: -1...1)
                    .tint(.accentBlue)
                    
                    Text("\(Int(position.height * 100))")
                        .font(.caption)
                        .frame(width: 30)
                }
            }
            .padding()
            .glassCard()
            
            // Scale Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Scale")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text("W:")
                        .font(.caption)
                        .frame(width: 20, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { scale.width },
                        set: { scale.width = $0 }
                    ), in: 0.1...3.0)
                    .tint(.accentBlue)
                    
                    Text("\(Int(scale.width * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                HStack {
                    Text("H:")
                        .font(.caption)
                        .frame(width: 20, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { scale.height },
                        set: { scale.height = $0 }
                    ), in: 0.1...3.0)
                    .tint(.accentBlue)
                    
                    Text("\(Int(scale.height * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                Button("Lock Aspect Ratio") {
                    // TODO: Implement aspect ratio locking
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .padding()
            .glassCard()
            
            // Rotation Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Rotation")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Slider(value: $rotation, in: -180...180)
                        .tint(.accentBlue)
                    
                    Text("\(Int(rotation))°")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                HStack {
                    Button("Reset") {
                        rotation = 0
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    
                    Button("90°") {
                        rotation += 90
                        if rotation > 180 { rotation -= 360 }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    
                    Button("-90°") {
                        rotation -= 90
                        if rotation < -180 { rotation += 360 }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .glassCard()
            
            // Crop Controls
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Crop")
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Toggle("", isOn: $cropEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .accentBlue))
                }
                
                if cropEnabled {
                    VStack(spacing: 8) {
                        Button("Auto Crop to 16:9") {
                            // TODO: Implement auto crop
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Auto Crop to 9:16") {
                            // TODO: Implement auto crop
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Auto Crop to 1:1") {
                            // TODO: Implement auto crop
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .glassCard()
            
            // Flip Controls
            HStack {
                Button("Flip Horizontal") {
                    // TODO: Implement flip
                }
                .buttonStyle(.bordered)
                
                Button("Flip Vertical") {
                    // TODO: Implement flip
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Clip Effects View
struct ClipEffectsView: View {
    let clip: TimelineClip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Clip Effects")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Text("Apply effects specifically to this clip")
                .font(.caption)
                .foregroundColor(.secondaryText)
            
            // Effect categories would go here - similar to track effects
            Text("Coming Soon: Clip-specific effects")
                .font(.caption)
                .foregroundColor(.secondaryText)
                .padding()
                .glassCard()
        }
    }
}

// MARK: - Audio Editor View
struct AudioEditorView: View {
    let clip: TimelineClip
    @State private var volume: Float
    @State private var fadeIn: TimeInterval = 0
    @State private var fadeOut: TimeInterval = 0
    
    init(clip: TimelineClip) {
        self.clip = clip
        self._volume = State(initialValue: clip.volume)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Volume Control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(Int(volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Slider(value: $volume, in: 0...2)
                    .tint(.accentBlue)
            }
            .padding()
            .glassCard()
            
            // Fade Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Fade")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text("In:")
                        .font(.caption)
                        .frame(width: 20, alignment: .leading)
                    
                    Slider(value: $fadeIn, in: 0...5)
                        .tint(.accentBlue)
                    
                    Text("\(fadeIn, specifier: "%.1f")s")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                HStack {
                    Text("Out:")
                        .font(.caption)
                        .frame(width: 20, alignment: .leading)
                    
                    Slider(value: $fadeOut, in: 0...5)
                        .tint(.accentBlue)
                    
                    Text("\(fadeOut, specifier: "%.1f")s")
                        .font(.caption)
                        .frame(width: 30)
                }
            }
            .padding()
            .glassCard()
            
            // Audio Effects
            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Effects")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                Button("Normalize Audio") {
                    // TODO: Implement normalize
                }
                .buttonStyle(.bordered)
                
                Button("Noise Reduction") {
                    // TODO: Implement noise reduction
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .glassCard()
        }
    }
}

// MARK: - Speed Editor View
struct SpeedEditorView: View {
    let clip: TimelineClip
    @State private var speed: Double
    @State private var maintainPitch: Bool = true
    @State private var reverseClip: Bool = false
    
    init(clip: TimelineClip) {
        self.clip = clip
        self._speed = State(initialValue: clip.speed)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Speed & Time")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Speed Control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speed")
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(speed, specifier: "%.2f")x")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Slider(value: $speed, in: 0.1...5.0)
                    .tint(.accentBlue)
                
                HStack {
                    Button("0.25x") { speed = 0.25 }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    
                    Button("0.5x") { speed = 0.5 }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    
                    Button("1x") { speed = 1.0 }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    
                    Button("2x") { speed = 2.0 }
                        .font(.caption)
                        .buttonStyle(.bordered)
                }
            }
            .padding()
            .glassCard()
            
            // Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Options")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                Toggle("Maintain Pitch", isOn: $maintainPitch)
                    .toggleStyle(SwitchToggleStyle(tint: .accentBlue))
                
                Toggle("Reverse Clip", isOn: $reverseClip)
                    .toggleStyle(SwitchToggleStyle(tint: .accentBlue))
            }
            .padding()
            .glassCard()
            
            // Duration Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration Info")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text("Original:")
                        .font(.caption)
                    Text("\(clip.duration, specifier: "%.2f")s")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                HStack {
                    Text("New:")
                        .font(.caption)
                    Text("\(clip.duration / speed, specifier: "%.2f")s")
                        .font(.caption)
                        .foregroundColor(.accentBlue)
                }
            }
            .padding()
            .glassCard()
        }
    }
}

// MARK: - Clip Timeline View
struct ClipTimelineView: View {
    let clip: TimelineClip
    @Binding var previewTime: TimeInterval
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Timeline")
                    .font(.caption.bold())
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(previewTime, specifier: "%.2f")s / \(clip.duration, specifier: "%.2f")s")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Slider(value: $previewTime, in: 0...clip.duration)
                .tint(.accentBlue)
        }
        .padding()
        .glassCard()
    }
}

#Preview {
    let sampleURL = URL(fileURLWithPath: "/tmp/sample.mp4")
    let mediaItem = MediaItem(url: sampleURL)
    
    ClipEditorView(
        clip: TimelineClip(
            mediaItem: mediaItem,
            startTime: 0,
            trackIndex: 0
        ),
        viewModel: MainViewModel()
    )
} 