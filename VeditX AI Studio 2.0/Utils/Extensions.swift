import Foundation
import SwiftUI
import AVFoundation

// MARK: - TimeInterval Extensions
extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        let milliseconds = Int((self.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var shortFormattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Color Extensions
extension Color {
    static let glassPrimary = Color.white.opacity(0.2)
    static let glassSecondary = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.3)
    
    // Timeline colors
    static let timelineVideo = Color(hex: "3b82f6")     // Blue
    static let timelineAudio = Color(hex: "10b981")     // Green
    static let timelineSubtitle = Color(hex: "f59e0b")  // Yellow
    static let timelineImage = Color(hex: "8b5cf6")     // Purple
    
    // UI Colors
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let accentBlue = Color.blue
    static let accentOrange = Color.orange
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func glassBackground() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
    }
    
    func glassCard() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.glassBorder, lineWidth: 0.5)
                    )
            )
    }
    
    func aiToolButton() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentBlue.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentBlue, lineWidth: 1)
                    )
            )
    }
    
    func timelineClipStyle(color: Color) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color, lineWidth: 1)
                    )
            )
    }
}

// MARK: - CGSize Extensions
extension CGSize {
    static let thumbnailSize = CGSize(width: 120, height: 80)
    static let timelineClipHeight = CGSize(width: 0, height: 60)
}

// MARK: - URL Extensions
extension URL {
    var isVideo: Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv"]
        return videoExtensions.contains(self.pathExtension.lowercased())
    }
    
    var isAudio: Bool {
        let audioExtensions = ["mp3", "wav", "aac", "m4a", "flac", "ogg", "wma"]
        return audioExtensions.contains(self.pathExtension.lowercased())
    }
    
    var isImage: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
        return imageExtensions.contains(self.pathExtension.lowercased())
    }
}

// MARK: - CMTime Extensions
extension CMTime {
    var timeInterval: TimeInterval {
        return CMTimeGetSeconds(self)
    }
    
    init(timeInterval: TimeInterval) {
        self = CMTime(seconds: timeInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
} 