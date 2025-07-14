import Foundation

// MARK: - Project Model
struct Project: Identifiable, Codable {
    let id = UUID()
    var name: String
    var timeline: Timeline
    var mediaItems: [MediaItem]
    var subtitles: [Subtitle]
    var createdAt: Date
    var modifiedAt: Date
    var projectURL: URL?
    
    // Export settings
    var exportSettings: ExportSettings
    
    init(name: String) {
        self.name = name
        self.timeline = Timeline()
        self.mediaItems = []
        self.subtitles = []
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.exportSettings = ExportSettings()
    }
    
    mutating func addMediaItem(_ item: MediaItem) {
        mediaItems.append(item)
        modifiedAt = Date()
    }
    
    mutating func removeMediaItem(withId id: UUID) {
        mediaItems.removeAll { $0.id == id }
        // Also remove any timeline clips using this media
        timeline.tracks = timeline.tracks.map { track in
            var updatedTrack = track
            updatedTrack.clips.removeAll { $0.mediaItem.id == id }
            return updatedTrack
        }
        modifiedAt = Date()
    }
    
    mutating func addSubtitle(_ subtitle: Subtitle) {
        subtitles.append(subtitle)
        modifiedAt = Date()
    }
    
    mutating func updateTimeline(_ newTimeline: Timeline) {
        timeline = newTimeline
        modifiedAt = Date()
    }
}

// MARK: - Export Settings Model
struct ExportSettings: Codable {
    var resolution: VideoResolution = .hd1080
    var frameRate: Int = 30
    var quality: VideoQuality = .high
    var format: ExportFormat = .mp4
    var includeAudio: Bool = true
    var includeSubtitles: Bool = true
    
    enum VideoResolution: String, Codable, CaseIterable {
        case sd480 = "480p"
        case hd720 = "720p"
        case hd1080 = "1080p"
        case uhd4k = "4K"
        
        var dimensions: (width: Int, height: Int) {
            switch self {
            case .sd480: return (854, 480)
            case .hd720: return (1280, 720)
            case .hd1080: return (1920, 1080)
            case .uhd4k: return (3840, 2160)
            }
        }
    }
    
    enum VideoQuality: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case ultra = "Ultra"
        
        var bitrate: Int {
            switch self {
            case .low: return 1000000 // 1 Mbps
            case .medium: return 5000000 // 5 Mbps
            case .high: return 10000000 // 10 Mbps
            case .ultra: return 20000000 // 20 Mbps
            }
        }
    }
    
    enum ExportFormat: String, Codable, CaseIterable {
        case mp4 = "MP4"
        case mov = "MOV"
        case avi = "AVI"
        
        var fileExtension: String {
            switch self {
            case .mp4: return "mp4"
            case .mov: return "mov"
            case .avi: return "avi"
            }
        }
    }
}

// MARK: - Export Preset Model
struct ExportPreset: Identifiable, Codable {
    let id = UUID()
    let name: String
    let settings: ExportSettings
    let platform: Platform
    
    var description: String {
        return "\(settings.resolution.rawValue) • \(settings.frameRate)fps • \(settings.quality.rawValue)"
    }
    
    enum Platform: String, Codable, CaseIterable {
        case youtube = "YouTube"
        case instagram = "Instagram"
        case tiktok = "TikTok"
        case custom = "Custom"
        
        var systemImage: String {
            switch self {
            case .youtube: return "play.rectangle.fill"
            case .instagram: return "camera.fill"
            case .tiktok: return "music.note"
            case .custom: return "gear"
            }
        }
    }
    
    static let defaultPresets: [ExportPreset] = [
        ExportPreset(
            name: "YouTube 1080p",
            settings: ExportSettings(
                resolution: .hd1080,
                frameRate: 30,
                quality: .high,
                format: .mp4
            ),
            platform: .youtube
        ),
        ExportPreset(
            name: "Instagram Story",
            settings: ExportSettings(
                resolution: .hd1080,
                frameRate: 30,
                quality: .high,
                format: .mp4
            ),
            platform: .instagram
        ),
        ExportPreset(
            name: "TikTok Vertical",
            settings: ExportSettings(
                resolution: .hd1080,
                frameRate: 30,
                quality: .high,
                format: .mp4
            ),
            platform: .tiktok
        )
    ]
} 