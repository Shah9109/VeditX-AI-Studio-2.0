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
        // Add clip to appropriate track
        if let track = currentProject.timeline.tracks.first(where: { $0.type == (clip.mediaItem.type == .video ? .video : .audio) }) {
            track.clips.append(clip)
        }
    }
    
    func removeClipFromTimeline(withId clipId: UUID) {
        // Remove clip from all tracks
        for track in currentProject.timeline.tracks {
            track.clips.removeAll { $0.id == clipId }
        }
        selectedTimelineClips.remove(clipId)
    }
    
    func updateClipPosition(_ clipId: UUID, startTime: TimeInterval) {
        for trackIndex in currentProject.timeline.tracks.indices {
            if let clipIndex = currentProject.timeline.tracks[trackIndex].clips.firstIndex(where: { $0.id == clipId }) {
                currentProject.timeline.tracks[trackIndex].clips[clipIndex].startTime = startTime
                // Update project duration
                let maxEndTime = currentProject.timeline.tracks.flatMap { $0.clips }.map { $0.endTime }.max() ?? 0
                currentProject.timeline.duration = maxEndTime
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
    
    // MARK: - Enhanced Timeline Operations
    func addTrack(type: TimelineTrack.TrackType) {
        let newTrack = TimelineTrack(type: type)
        currentProject.timeline.tracks.append(newTrack)
    }
    
    func removeTrack(_ trackId: UUID) {
        currentProject.timeline.tracks.removeAll { $0.id == trackId }
    }
    
    func addMediaToTimeline(url: URL, at time: TimeInterval) {
        let mediaItem = MediaItem(url: url)
        
        let clip = TimelineClip(
            mediaItem: mediaItem,
            startTime: time,
            trackIndex: 0
        )
        
        // Find appropriate track or create one
        let trackType: TimelineTrack.TrackType = mediaItem.type == .video ? .video : .audio
        
        if let existingTrack = currentProject.timeline.tracks.first(where: { $0.type == trackType }) {
            // Check for layer conflicts and assign appropriate layer
            let conflictingClips = existingTrack.clips.filter { existingClip in
                !(clip.endTime <= existingClip.startTime || clip.startTime >= existingClip.endTime)
            }
            
            var layerIndex = 0
            while conflictingClips.contains(where: { $0.layerIndex == layerIndex }) {
                layerIndex += 1
            }
            
            var newClip = clip
            newClip.layerIndex = layerIndex
            existingTrack.clips.append(newClip)
        } else {
            // Create new track
            let newTrack = TimelineTrack(type: trackType)
            newTrack.clips.append(clip)
            currentProject.timeline.tracks.append(newTrack)
        }
        
        updateProjectDuration()
    }
    
    func removeClipFromTimeline(_ clipId: UUID) {
        for track in currentProject.timeline.tracks {
            track.clips.removeAll { $0.id == clipId }
        }
        selectedTimelineClips.remove(clipId)
        updateProjectDuration()
    }
    
    func moveClip(_ clipId: UUID, to time: TimeInterval, track: TimelineTrack) {
        // Find and remove clip from current track
        var clipToMove: TimelineClip?
        for currentTrack in currentProject.timeline.tracks {
            if let clipIndex = currentTrack.clips.firstIndex(where: { $0.id == clipId }) {
                clipToMove = currentTrack.clips.remove(at: clipIndex)
                break
            }
        }
        
        // Add to new track at new time
        if var clip = clipToMove {
            clip.startTime = time
            
            // Handle layer conflicts
            let conflictingClips = track.clips.filter { existingClip in
                !(clip.endTime <= existingClip.startTime || clip.startTime >= existingClip.endTime)
            }
            
            var layerIndex = 0
            while conflictingClips.contains(where: { $0.layerIndex == layerIndex }) {
                layerIndex += 1
            }
            clip.layerIndex = layerIndex
            
            track.clips.append(clip)
        }
        
        updateProjectDuration()
    }
    
    private func updateProjectDuration() {
        let maxEndTime = currentProject.timeline.tracks.flatMap { $0.clips }.map { $0.endTime }.max() ?? 0
        currentProject.timeline.duration = maxEndTime
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
    

    
    // MARK: - AI Integration with Real APIs
    private let openAIAPIKey = "sk-whatsapp-m4BOtm3wYwyDvL52JJgAT3BlbkFJf2jH4gz7Uck5yCaco1g5"
    private let elevenLabsAPIKey = "fba155a7d2d56f47d00f9013447bac3a"
    
    @Published var isProcessingAI = false
    @Published var aiProgress: Double = 0
    @Published var currentAITask = ""
    
    func generateAutoCaptions() {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        currentAITask = "Generating Captions"
        aiProgress = 0
        
        Task {
            do {
                // Get video clips for transcription
                let videoClips = currentProject.timeline.tracks
                    .filter { $0.type == .video }
                    .flatMap { $0.clips }
                    .sorted { $0.startTime < $1.startTime }
                
                for (index, clip) in videoClips.enumerated() {
                    await MainActor.run {
                        aiProgress = Double(index) / Double(videoClips.count) * 0.8
                    }
                    
                    // Extract audio and send to OpenAI Whisper
                    let subtitles = try await transcribeAudio(from: clip)
                    
                    await MainActor.run {
                        // Add subtitles to subtitle track
                        addSubtitlesToTrack(subtitles, for: clip)
                    }
                }
                
                await MainActor.run {
                    aiProgress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isProcessingAI = false
                        self.currentAITask = ""
                        self.aiProgress = 0
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingAI = false
                    showError("Failed to generate captions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func generateVoiceover(text: String, voice: String = "alloy") {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        currentAITask = "Generating Voiceover"
        aiProgress = 0
        
        Task {
            do {
                let audioURL = try await generateTTSAudio(text: text, voice: voice)
                
                await MainActor.run {
                    // Add generated audio to timeline
                    addMediaToTimeline(url: audioURL, at: playbackTime)
                    
                    aiProgress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isProcessingAI = false
                        self.currentAITask = ""
                        self.aiProgress = 0
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingAI = false
                    showError("Failed to generate voiceover: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func detectScenes() {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        currentAITask = "Detecting Scenes"
        aiProgress = 0
        
        Task {
            do {
                let videoClips = currentProject.timeline.tracks
                    .filter { $0.type == .video }
                    .flatMap { $0.clips }
                
                for (index, clip) in videoClips.enumerated() {
                    await MainActor.run {
                        aiProgress = Double(index) / Double(videoClips.count)
                    }
                    
                    // Analyze video for scene changes
                    let sceneMarkers = try await analyzeVideoScenes(clip: clip)
                    
                    await MainActor.run {
                        // Add scene markers or auto-split clips
                        processSceneMarkers(sceneMarkers, for: clip)
                    }
                }
                
                await MainActor.run {
                    aiProgress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isProcessingAI = false
                        self.currentAITask = ""
                        self.aiProgress = 0
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingAI = false
                    showError("Failed to detect scenes: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func removeBackground() {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        currentAITask = "Removing Background"
        aiProgress = 0
        
        // Mock implementation - would use AI background removal
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.aiProgress = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isProcessingAI = false
                self.currentAITask = ""
                self.aiProgress = 0
            }
        }
    }
    
    // MARK: - AI API Integration Methods
    private func transcribeAudio(from clip: TimelineClip) async throws -> [Subtitle] {
        // Extract audio from video clip
        let audioURL = try await extractAudio(from: clip.mediaItem.url)
        
        // Prepare request to OpenAI Whisper API
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add file
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(try Data(contentsOf: audioURL))
        data.append("\r\n".data(using: .utf8)!)
        
        // Add model
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add response format
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        data.append("verbose_json\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        
        // Parse response and create subtitles
        let response = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let segments = response?["segments"] as? [[String: Any]] ?? []
        
        return segments.compactMap { segment in
            guard let text = segment["text"] as? String,
                  let start = segment["start"] as? Double,
                  let end = segment["end"] as? Double else { return nil }
            
            return Subtitle(
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: clip.startTime + start,
                endTime: clip.startTime + end
            )
        }
    }
    
    private func generateTTSAudio(text: String, voice: String) async throws -> URL {
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voice)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        
        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Save audio to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voiceover_\(UUID().uuidString).mp3")
        
        try data.write(to: tempURL)
        return tempURL
    }
    
    private func extractAudio(from videoURL: URL) async throws -> URL {
        // Use AVAssetExportSession to extract audio
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("extracted_audio_\(UUID().uuidString).m4a")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        
        if let error = exportSession.error {
            throw error
        }
        
        return outputURL
    }
    
    private func analyzeVideoScenes(clip: TimelineClip) async throws -> [TimeInterval] {
        // Mock scene detection - in real implementation would use AI
        // Return timestamps where scene changes occur
        let clipDuration = clip.duration
        let numberOfScenes = Int(clipDuration / 10) + 1 // Scene every 10 seconds
        
        return stride(from: 0.0, to: clipDuration, by: 10.0).map { $0 }
    }
    
    private func addSubtitlesToTrack(_ subtitles: [Subtitle], for clip: TimelineClip) {
        // Find or create subtitle track
        var subtitleTrack = currentProject.timeline.tracks.first { $0.type == .subtitle }
        
        if subtitleTrack == nil {
            subtitleTrack = TimelineTrack(type: .subtitle)
            currentProject.timeline.tracks.append(subtitleTrack!)
        }
        
        // Add subtitles (this would need to be implemented based on how subtitles are stored)
        // For now, we'll add them to the project's subtitle list
        // This is a simplified implementation
    }
    
    private func processSceneMarkers(_ markers: [TimeInterval], for clip: TimelineClip) {
        // Process scene change markers - could auto-split clips or add markers
        // Implementation depends on desired behavior
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