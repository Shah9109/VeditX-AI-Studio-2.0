import Foundation
import SwiftUI
import AVFoundation
import Combine

// MARK: - Main View Model
@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentProject: Project = Project(name: "Untitled Project")
    @Published var selectedTab: TabType = .media
    @Published var selectedMediaItems: Set<UUID> = []
    @Published var selectedTimelineClips: Set<UUID> = []
    @Published var isPlaying: Bool = false
    @Published var playbackTime: TimeInterval = 0
    @Published var showingImportPanel: Bool = false
    @Published var showingExportPanel: Bool = false
    @Published var showingProjectSavePanel: Bool = false
    @Published var showingProjectOpenPanel: Bool = false
    @Published var exportProgress: Double = 0
    @Published var isExporting: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    
    // MARK: - Private Properties
    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Tab Types
    enum TabType: String, CaseIterable {
        case media = "Media"
        case audio = "Audio"
        case text = "Text"
        case effects = "Effects"
        case aiTools = "AI Tools"
        
        var systemImage: String {
            switch self {
            case .media: return "photo.on.rectangle"
            case .audio: return "waveform"
            case .text: return "textformat"
            case .effects: return "sparkles"
            case .aiTools: return "brain.head.profile"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update timeline when clips change
        $currentProject
            .map { $0.timeline }
            .removeDuplicates { $0.duration == $1.duration }
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Media Management
    func importMedia(from urls: [URL]) {
        for url in urls {
            let mediaItem = MediaItem(url: url)
            currentProject.addMediaItem(mediaItem)
            
            // Generate thumbnail for videos
            if mediaItem.type == .video {
                generateThumbnail(for: mediaItem)
            }
        }
    }
    
    private func generateThumbnail(for mediaItem: MediaItem) {
        let asset = AVAsset(url: mediaItem.url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 60)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, image, _, _, _ in
            guard let image = image else { return }
            
            let nsImage = NSImage(cgImage: image, size: .thumbnailSize)
            if let tiffData = nsImage.tiffRepresentation {
                DispatchQueue.main.async {
                    // Update media item with thumbnail data
                    if let index = self?.currentProject.mediaItems.firstIndex(where: { $0.id == mediaItem.id }) {
                        self?.currentProject.mediaItems[index].thumbnailData = tiffData
                    }
                }
            }
        }
    }
    
    func removeMediaItem(withId id: UUID) {
        currentProject.removeMediaItem(withId: id)
        selectedMediaItems.remove(id)
    }
    
    // MARK: - Timeline Management
    func addClipToTimeline(_ mediaItem: MediaItem, at time: TimeInterval, trackIndex: Int) {
        let clip = TimelineClip(mediaItem: mediaItem, startTime: time, trackIndex: trackIndex)
        currentProject.timeline.addClip(clip)
    }
    
    func removeClipFromTimeline(withId clipId: UUID) {
        currentProject.timeline.removeClip(withId: clipId)
        selectedTimelineClips.remove(clipId)
    }
    
    func updateClipPosition(_ clipId: UUID, startTime: TimeInterval) {
        for trackIndex in currentProject.timeline.tracks.indices {
            if let clipIndex = currentProject.timeline.tracks[trackIndex].clips.firstIndex(where: { $0.id == clipId }) {
                currentProject.timeline.tracks[trackIndex].clips[clipIndex].startTime = startTime
                currentProject.timeline.updateDuration()
                break
            }
        }
    }
    
    // MARK: - Playback Control
    func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            startPlayback()
        } else {
            stopPlayback()
        }
    }
    
    private func startPlayback() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.playbackTime += 1.0/30.0
            
            if self.playbackTime >= self.currentProject.timeline.duration {
                self.stopPlayback()
                self.playbackTime = 0
            }
        }
    }
    
    public func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func seekTo(time: TimeInterval) {
        playbackTime = max(0, min(time, currentProject.timeline.duration))
    }
    
    // MARK: - Timeline Operations
    func addMediaToTimeline(url: URL, at time: TimeInterval) {
        let mediaItem = MediaItem(url: url)
        
        let clip = TimelineClip(
            mediaItem: mediaItem,
            startTime: time,
            trackIndex: 0
        )
        
        // Add to appropriate track based on media type
        let trackType: TimelineTrack.TrackType = mediaItem.type == .video ? .video : .audio
        
        if let existingTrackIndex = currentProject.timeline.tracks.firstIndex(where: { $0.type == trackType }) {
            currentProject.timeline.tracks[existingTrackIndex].clips.append(clip)
        } else {
            var newTrack = TimelineTrack(type: trackType)
            newTrack.clips.append(clip)
            currentProject.timeline.tracks.append(newTrack)
        }
    }
    
    func addNewTrack() {
        let newTrack = TimelineTrack(type: .video)
        currentProject.timeline.tracks.append(newTrack)
    }
    
    func removeClipFromTimeline(_ clipId: UUID) {
        for i in 0..<currentProject.timeline.tracks.count {
            currentProject.timeline.tracks[i].clips.removeAll { $0.id == clipId }
        }
        selectedTimelineClips.remove(clipId)
    }
    
    func moveClip(_ clipId: UUID, to time: TimeInterval, trackIndex: Int) {
        // Find and remove clip from current track
        var clipToMove: TimelineClip?
        for i in 0..<currentProject.timeline.tracks.count {
            if let clipIndex = currentProject.timeline.tracks[i].clips.firstIndex(where: { $0.id == clipId }) {
                clipToMove = currentProject.timeline.tracks[i].clips.remove(at: clipIndex)
                break
            }
        }
        
        // Add to new track at new time
        if var clip = clipToMove {
            clip.startTime = time
            if trackIndex < currentProject.timeline.tracks.count {
                currentProject.timeline.tracks[trackIndex].clips.append(clip)
            }
        }
    }
    
    // MARK: - Enhanced Export System
    func exportWithPreset(_ preset: ExportPreset) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.movie]
        panel.nameFieldStringValue = "\(currentProject.name)_\(preset.name)"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.exportVideo(with: preset, to: url)
                }
            }
        }
    }
    
    func exportVideo(with preset: ExportPreset, to url: URL) {
        isExporting = true
        exportProgress = 0
        
        // Enhanced export simulation with realistic progress
        let exportTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Simulate variable export speed
            let increment = Double.random(in: 0.02...0.08)
            self.exportProgress = min(1.0, self.exportProgress + increment)
            
            if self.exportProgress >= 1.0 {
                timer.invalidate()
                self.isExporting = false
                self.exportProgress = 0
                
                // Show completion notification
                let notification = NSUserNotification()
                notification.title = "Export Complete"
                notification.informativeText = "Video exported successfully to \(url.lastPathComponent)"
                NSUserNotificationCenter.default.deliver(notification)
                
                print("Export completed: \(url.path)")
            }
        }
        
        // Store timer reference for potential cancellation
        RunLoop.current.add(exportTimer, forMode: .common)
    }
    
    // MARK: - Project Management with File Operations
    func newProject() {
        createNewProject(name: "Untitled Project")
    }
    
    func createNewProject(name: String) {
        currentProject = Project(name: name)
        selectedMediaItems.removeAll()
        selectedTimelineClips.removeAll()
        playbackTime = 0
        stopPlayback()
    }
    
    func saveProject() {
        if let existingURL = currentProject.projectURL {
            saveProject(to: existingURL)
        } else {
            saveProjectAs()
        }
    }
    
    func saveProjectAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "veditx")!]
        panel.nameFieldStringValue = currentProject.name
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.saveProject(to: url)
                }
            }
        }
    }
    
    func saveProject(to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            currentProject.projectURL = url
            
            let data = try encoder.encode(currentProject)
            try data.write(to: url)
            
            print("Project saved successfully to: \(url.path)")
        } catch {
            showError("Failed to save project: \(error.localizedDescription)")
        }
    }
    
    func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "veditx")!]
        panel.allowsMultipleSelection = false
        
        panel.begin { result in
            if result == .OK, let url = panel.urls.first {
                DispatchQueue.main.async {
                    self.loadProjectFromURL(url)
                }
            }
        }
    }
    
    func loadProjectFromURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            currentProject = try decoder.decode(Project.self, from: data)
            currentProject.projectURL = url
            
            // Reset UI state
            selectedMediaItems.removeAll()
            selectedTimelineClips.removeAll()
            playbackTime = 0
            stopPlayback()
        } catch {
            showError("Failed to load project: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AI Features (Mock Implementation)
    func generateAutoCaption() {
        // Mock implementation - in real app would use Whisper or speech recognition
        let subtitle = Subtitle(
            text: "What an amazing play!",
            startTime: playbackTime,
            endTime: playbackTime + 3.0
        )
        currentProject.addSubtitle(subtitle)
    }
    
    func generateAIVoiceover(text: String) {
        // Mock implementation - in real app would use ElevenLabs or AVSpeechSynthesizer
        print("Generating AI voiceover for: \(text)")
    }
    
    func detectScenes() {
        // Mock implementation - in real app would use Vision API
        print("Detecting scenes in video...")
    }
    
    func removeBackground() {
        // Mock implementation - in real app would use Vision person segmentation
        print("Removing background from video...")
    }
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    // MARK: - Selection Management
    func selectMediaItem(_ id: UUID) {
        if selectedMediaItems.contains(id) {
            selectedMediaItems.remove(id)
        } else {
            selectedMediaItems.insert(id)
        }
    }
    
    func selectTimelineClip(_ id: UUID) {
        if selectedTimelineClips.contains(id) {
            selectedTimelineClips.remove(id)
        } else {
            selectedTimelineClips.insert(id)
        }
    }
    
    func clearSelections() {
        selectedMediaItems.removeAll()
        selectedTimelineClips.removeAll()
    }
} 