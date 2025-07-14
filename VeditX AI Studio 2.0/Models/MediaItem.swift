import Foundation
import AVFoundation
import CoreGraphics

// MARK: - Media Item Model
struct MediaItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let type: MediaType
    let duration: TimeInterval
    let createdAt: Date
    var thumbnailData: Data?
    
    enum MediaType: String, Codable, CaseIterable {
        case video = "video"
        case audio = "audio"
        case image = "image"
        
        var systemImage: String {
            switch self {
            case .video: return "video.fill"
            case .audio: return "waveform"
            case .image: return "photo.fill"
            }
        }
        
        var color: String {
            switch self {
            case .video: return "orange"
            case .audio: return "blue" 
            case .image: return "green"
            }
        }
    }
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.createdAt = Date()
        
        // Determine media type based on file extension
        let pathExtension = url.pathExtension.lowercased()
        if ["mp4", "mov", "avi", "mkv", "m4v"].contains(pathExtension) {
            self.type = .video
        } else if ["mp3", "wav", "aac", "m4a", "flac"].contains(pathExtension) {
            self.type = .audio
        } else {
            self.type = .image
        }
        
        // Get duration for video/audio files
        if type == .video || type == .audio {
            let asset = AVAsset(url: url)
            self.duration = CMTimeGetSeconds(asset.duration)
        } else {
            self.duration = 5.0 // Default duration for images
        }
    }
} 