import Foundation
import CoreGraphics

// MARK: - Timeline Clip Model
struct TimelineClip: Identifiable, Codable, Equatable {
    let id = UUID()
    let mediaItem: MediaItem
    var startTime: TimeInterval // Start time on timeline
    var duration: TimeInterval // Duration on timeline (can be trimmed)
    var trimStart: TimeInterval // Trim from start of original media
    var trimEnd: TimeInterval // Trim from end of original media
    var trackIndex: Int // Which track this clip is on
    var volume: Float // 0.0 to 1.0
    var isSelected: Bool = false
    
    init(mediaItem: MediaItem, startTime: TimeInterval, trackIndex: Int) {
        self.mediaItem = mediaItem
        self.startTime = startTime
        self.duration = mediaItem.duration
        self.trimStart = 0
        self.trimEnd = 0
        self.trackIndex = trackIndex
        self.volume = 1.0
    }
    
    var endTime: TimeInterval {
        return startTime + duration
    }
    
    var actualDuration: TimeInterval {
        return mediaItem.duration - trimStart - trimEnd
    }
}

// MARK: - Timeline Track Model
struct TimelineTrack: Identifiable, Codable, Equatable {
    let id = UUID()
    let type: TrackType
    var name: String
    var clips: [TimelineClip]
    var isMuted: Bool = false
    var isVisible: Bool = true
    var height: CGFloat = 60
    
    enum TrackType: String, Codable, CaseIterable {
        case video = "video"
        case audio = "audio"
        case subtitle = "subtitle"
        
        var color: String {
            switch self {
            case .video: return "orange"
            case .audio: return "blue"
            case .subtitle: return "green"
            }
        }
        
        var defaultName: String {
            switch self {
            case .video: return "Video Track"
            case .audio: return "Audio Track"
            case .subtitle: return "Subtitle Track"
            }
        }
    }
    
    init(type: TrackType) {
        self.type = type
        self.name = type.defaultName
        self.clips = []
    }
}

// MARK: - Timeline Model
struct Timeline: Codable {
    var tracks: [TimelineTrack]
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var zoomLevel: CGFloat = 1.0
    var scrollOffset: CGFloat = 0
    
    init() {
        // Initialize with default tracks
        self.tracks = [
            TimelineTrack(type: .video),
            TimelineTrack(type: .audio),
            TimelineTrack(type: .subtitle)
        ]
    }
    
    mutating func addClip(_ clip: TimelineClip) {
        if let trackIndex = tracks.firstIndex(where: { $0.id.uuidString == tracks[clip.trackIndex].id.uuidString }) {
            tracks[trackIndex].clips.append(clip)
            updateDuration()
        }
    }
    
    mutating func removeClip(withId clipId: UUID) {
        for trackIndex in tracks.indices {
            tracks[trackIndex].clips.removeAll { $0.id == clipId }
        }
        updateDuration()
    }
    
    mutating func updateDuration() {
        let maxEndTime = tracks.flatMap { $0.clips }.map { $0.endTime }.max() ?? 0
        self.duration = maxEndTime
    }
    
    func getClips(at time: TimeInterval) -> [TimelineClip] {
        return tracks.flatMap { $0.clips }.filter { clip in
            time >= clip.startTime && time <= clip.endTime
        }
    }
}

// MARK: - Subtitle Model
struct Subtitle: Identifiable, Codable {
    let id = UUID()
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var position: SubtitlePosition = .bottom
    
    enum SubtitlePosition: String, Codable, CaseIterable {
        case top = "top"
        case center = "center"
        case bottom = "bottom"
    }
    
    init(text: String, startTime: TimeInterval, endTime: TimeInterval) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
} 