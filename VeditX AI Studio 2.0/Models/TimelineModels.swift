import Foundation
import SwiftUI

// MARK: - Enhanced Timeline Models
struct Timeline: Codable, Identifiable {
    let id = UUID()
    var tracks: [TimelineTrack] = []
    var duration: TimeInterval = 0.0
    var frameRate: Double = 30.0
    var resolution: CGSize = CGSize(width: 1920, height: 1080)
    
    mutating func addTrack(type: TimelineTrack.TrackType) {
        let newTrack = TimelineTrack(type: type)
        tracks.append(newTrack)
    }
    
    mutating func removeTrack(id: UUID) {
        tracks.removeAll { $0.id == id }
    }
    
    mutating func reorderTracks(from source: IndexSet, to destination: Int) {
        tracks.move(fromOffsets: source, toOffset: destination)
    }
    
    func getClips(at time: TimeInterval) -> [TimelineClip] {
        return tracks.flatMap { $0.clips }.filter { clip in
            time >= clip.startTime && time <= clip.endTime
        }
    }
}

// MARK: - Enhanced Timeline Track
class TimelineTrack: ObservableObject, Identifiable, Codable, Equatable {
    let id = UUID()
    @Published var name: String
    @Published var type: TrackType
    @Published var clips: [TimelineClip] = []
    @Published var isVisible: Bool = true
    @Published var isLocked: Bool = false
    @Published var isMuted: Bool = false
    @Published var volume: Float = 1.0
    @Published var opacity: Float = 1.0
    @Published var effects: [VideoEffect] = []
    
    enum TrackType: String, Codable, CaseIterable {
        case video = "Video"
        case audio = "Audio"
        case subtitle = "Subtitle"
        case text = "Text"
        case effect = "Effect"
        
        var icon: String {
            switch self {
            case .video: return "video.fill"
            case .audio: return "waveform"
            case .subtitle: return "captions.bubble.fill"
            case .text: return "textformat"
            case .effect: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .video: return .timelineVideo
            case .audio: return .timelineAudio
            case .subtitle: return .timelineSubtitle
            case .text: return .timelineText
            case .effect: return .timelineEffect
            }
        }
    }
    
    init(type: TrackType) {
        self.type = type
        self.name = "\(type.rawValue) Track"
    }
    
    // MARK: - Codable Support
    enum CodingKeys: CodingKey {
        case id, name, type, clips, isVisible, isLocked, isMuted, volume, opacity, effects
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(TrackType.self, forKey: .type)
        clips = try container.decode([TimelineClip].self, forKey: .clips)
        isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? false
        volume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        opacity = try container.decodeIfPresent(Float.self, forKey: .opacity) ?? 1.0
        effects = try container.decodeIfPresent([VideoEffect].self, forKey: .effects) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(clips, forKey: .clips)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(isMuted, forKey: .isMuted)
        try container.encode(volume, forKey: .volume)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(effects, forKey: .effects)
    }
    
    // MARK: - Equatable
    static func == (lhs: TimelineTrack, rhs: TimelineTrack) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Enhanced Timeline Clip
struct TimelineClip: Identifiable, Codable {
    let id = UUID()
    var mediaItem: MediaItem
    var startTime: TimeInterval
    var duration: TimeInterval
    var trackIndex: Int
    var layerIndex: Int = 0
    var trimStart: TimeInterval = 0
    var trimEnd: TimeInterval = 0
    var speed: Double = 1.0
    var volume: Float = 1.0
    var opacity: Float = 1.0
    var transform: ClipTransform = ClipTransform()
    var effects: [VideoEffect] = []
    
    var endTime: TimeInterval {
        return startTime + duration
    }
    
    var actualDuration: TimeInterval {
        return (duration - trimStart - trimEnd) / speed
    }
    
    init(mediaItem: MediaItem, startTime: TimeInterval, trackIndex: Int) {
        self.mediaItem = mediaItem
        self.startTime = startTime
        self.duration = mediaItem.duration
        self.trackIndex = trackIndex
    }
}

// MARK: - Clip Transform
struct ClipTransform: Codable {
    var position: CGPoint = .zero
    var scale: CGSize = CGSize(width: 1.0, height: 1.0)
    var rotation: Double = 0.0
    var anchor: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var cropRect: CGRect?
    var flipHorizontal: Bool = false
    var flipVertical: Bool = false
}

// MARK: - Video Effects
class VideoEffect: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var type: EffectType
    @Published var parameters: [String: EffectParameter]
    @Published var isEnabled: Bool = true
    @Published var intensity: Float = 1.0
    
    enum EffectType: String, Codable, CaseIterable {
        // Color Effects
        case brightness = "Brightness"
        case contrast = "Contrast"
        case saturation = "Saturation"
        case hue = "Hue"
        case gamma = "Gamma"
        case exposure = "Exposure"
        case shadows = "Shadows"
        case highlights = "Highlights"
        case temperature = "Temperature"
        case tint = "Tint"
        
        // Blur Effects
        case gaussianBlur = "Gaussian Blur"
        case motionBlur = "Motion Blur"
        case radialBlur = "Radial Blur"
        case surfaceBlur = "Surface Blur"
        
        // Stylize Effects
        case vignette = "Vignette"
        case filmGrain = "Film Grain"
        case vintage = "Vintage"
        case blackWhite = "Black & White"
        case sepia = "Sepia"
        case posterize = "Posterize"
        case pixelate = "Pixelate"
        case oilPainting = "Oil Painting"
        
        // Distortion Effects
        case fisheye = "Fisheye"
        case spherize = "Spherize"
        case pinch = "Pinch"
        case twirl = "Twirl"
        case kaleidoscope = "Kaleidoscope"
        
        // Generator Effects
        case lensFlare = "Lens Flare"
        case lightLeak = "Light Leak"
        case dust = "Dust & Scratches"
        
        var category: EffectCategory {
            switch self {
            case .brightness, .contrast, .saturation, .hue, .gamma, .exposure, .shadows, .highlights, .temperature, .tint:
                return .color
            case .gaussianBlur, .motionBlur, .radialBlur, .surfaceBlur:
                return .blur
            case .vignette, .filmGrain, .vintage, .blackWhite, .sepia, .posterize, .pixelate, .oilPainting:
                return .stylize
            case .fisheye, .spherize, .pinch, .twirl, .kaleidoscope:
                return .distortion
            case .lensFlare, .lightLeak, .dust:
                return .generator
            }
        }
    }
    
    enum EffectCategory: String, CaseIterable {
        case color = "Color"
        case blur = "Blur"
        case stylize = "Stylize"
        case distortion = "Distortion"
        case generator = "Generator"
        
        var icon: String {
            switch self {
            case .color: return "slider.horizontal.3"
            case .blur: return "circle.dotted"
            case .stylize: return "paintbrush.fill"
            case .distortion: return "waveform.path"
            case .generator: return "sparkles"
            }
        }
    }
    
    init(type: EffectType) {
        self.name = type.rawValue
        self.type = type
        self.parameters = EffectParameter.defaultParameters(for: type)
    }
    
    // MARK: - Codable Support
    enum CodingKeys: CodingKey {
        case id, name, type, parameters, isEnabled, intensity
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(EffectType.self, forKey: .type)
        parameters = try container.decode([String: EffectParameter].self, forKey: .parameters)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        intensity = try container.decodeIfPresent(Float.self, forKey: .intensity) ?? 1.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(intensity, forKey: .intensity)
    }
}

// MARK: - Effect Parameters
struct EffectParameter: Codable {
    var floatValue: Float?
    var colorValue: [Float]? // RGBA
    var pointValue: [Float]? // x, y
    var boolValue: Bool?
    
    static func defaultParameters(for effectType: VideoEffect.EffectType) -> [String: EffectParameter] {
        switch effectType {
        case .brightness:
            return ["amount": EffectParameter(floatValue: 0.0)]
        case .contrast:
            return ["amount": EffectParameter(floatValue: 1.0)]
        case .saturation:
            return ["amount": EffectParameter(floatValue: 1.0)]
        case .hue:
            return ["angle": EffectParameter(floatValue: 0.0)]
        case .gamma:
            return ["power": EffectParameter(floatValue: 1.0)]
        case .gaussianBlur:
            return ["radius": EffectParameter(floatValue: 0.0)]
        case .vignette:
            return [
                "intensity": EffectParameter(floatValue: 0.5),
                "radius": EffectParameter(floatValue: 1.0)
            ]
        case .filmGrain:
            return [
                "amount": EffectParameter(floatValue: 0.1),
                "size": EffectParameter(floatValue: 1.0)
            ]
        default:
            return ["intensity": EffectParameter(floatValue: 1.0)]
        }
    }
}

// MARK: - Enhanced Subtitle
struct Subtitle: Identifiable, Codable {
    let id = UUID()
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var style: SubtitleStyle = SubtitleStyle()
    var position: CGPoint = CGPoint(x: 0.5, y: 0.9)
    var animation: SubtitleAnimation?
}

// MARK: - Subtitle Style
struct SubtitleStyle: Codable {
    var fontName: String = "Helvetica-Bold"
    var fontSize: CGFloat = 24
    var textColor: [Float] = [1.0, 1.0, 1.0, 1.0] // White
    var backgroundColor: [Float] = [0.0, 0.0, 0.0, 0.7] // Semi-transparent black
    var borderColor: [Float] = [0.0, 0.0, 0.0, 1.0] // Black
    var borderWidth: CGFloat = 1.0
    var cornerRadius: CGFloat = 4.0
    var padding: CGFloat = 8.0
    var alignment: TextAlignment = .center
    var shadow: ShadowStyle = ShadowStyle()
    
    enum TextAlignment: String, Codable, CaseIterable {
        case left = "left"
        case center = "center"
        case right = "right"
    }
}

// MARK: - Shadow Style
struct ShadowStyle: Codable {
    var color: [Float] = [0.0, 0.0, 0.0, 0.8] // Black
    var offset: CGSize = CGSize(width: 1, height: 1)
    var blur: CGFloat = 2.0
}

// MARK: - Subtitle Animation
struct SubtitleAnimation: Codable {
    var type: AnimationType
    var duration: TimeInterval = 0.5
    var delay: TimeInterval = 0.0
    
    enum AnimationType: String, Codable, CaseIterable {
        case fadeIn = "Fade In"
        case fadeOut = "Fade Out"
        case slideIn = "Slide In"
        case slideOut = "Slide Out"
        case typewriter = "Typewriter"
        case bounce = "Bounce"
        case scale = "Scale"
    }
} 