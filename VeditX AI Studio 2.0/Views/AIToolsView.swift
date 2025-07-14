import SwiftUI
import AVFoundation

struct AIToolsView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingCaptionSettings = false
    @State private var showingVoiceoverSettings = false
    @State private var showingSceneDetectionResults = false
    @State private var isProcessingAI = false
    @State private var currentAITask: String = ""
    @State private var aiProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("AI Tools")
                    .font(.title2.bold())
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if isProcessingAI {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    // Auto Captions Section
                    AIToolSection(
                        title: "Auto Captions",
                        systemImage: "captions.bubble.fill",
                        description: "Generate captions using AI speech recognition",
                        isProcessing: isProcessingAI && currentAITask == "captions",
                        progress: currentAITask == "captions" ? aiProgress : 0
                    ) {
                        generateAutoCaptions()
                    } settingsAction: {
                        showingCaptionSettings = true
                    }
                    
                    // AI Voiceover Section
                    AIToolSection(
                        title: "AI Voiceover",
                        systemImage: "speaker.wave.3.fill",
                        description: "Generate natural voice narration",
                        isProcessing: isProcessingAI && currentAITask == "voiceover",
                        progress: currentAITask == "voiceover" ? aiProgress : 0
                    ) {
                        showingVoiceoverSettings = true
                    } settingsAction: {
                        showingVoiceoverSettings = true
                    }
                    
                    // Scene Detection Section
                    AIToolSection(
                        title: "Scene Detection",
                        systemImage: "eye.fill",
                        description: "Automatically detect scene changes",
                        isProcessing: isProcessingAI && currentAITask == "scenes",
                        progress: currentAITask == "scenes" ? aiProgress : 0
                    ) {
                        detectScenes()
                    } settingsAction: {
                        showingSceneDetectionResults = true
                    }
                    
                    // Background Removal Section
                    AIToolSection(
                        title: "Background Removal",
                        systemImage: "person.crop.rectangle.fill",
                        description: "Remove or replace video background",
                        isProcessing: isProcessingAI && currentAITask == "background",
                        progress: currentAITask == "background" ? aiProgress : 0
                    ) {
                        removeBackground()
                    } settingsAction: {
                        // No settings for background removal
                    }
                    
                    // Audio Enhancement Section
                    AIToolSection(
                        title: "Audio Enhancement",
                        systemImage: "waveform.path",
                        description: "Noise reduction and audio cleanup",
                        isProcessing: isProcessingAI && currentAITask == "audio",
                        progress: currentAITask == "audio" ? aiProgress : 0
                    ) {
                        enhanceAudio()
                    } settingsAction: {
                        // No settings for audio enhancement
                    }
                    
                    // Smart Crop Section
                    AIToolSection(
                        title: "Smart Crop",
                        systemImage: "crop",
                        description: "Intelligent aspect ratio conversion",
                        isProcessing: isProcessingAI && currentAITask == "crop",
                        progress: currentAITask == "crop" ? aiProgress : 0
                    ) {
                        smartCrop()
                    } settingsAction: {
                        // No settings for smart crop
                    }
                }
            }
            
            Spacer()
            
            // Export Section
            ExportSection(viewModel: viewModel)
        }
        .padding()
        .glassEffect(cornerRadius: 12, material: .sidebar)
        .sheet(isPresented: $showingCaptionSettings) {
            CaptionSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingVoiceoverSettings) {
            VoiceoverSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSceneDetectionResults) {
            SceneDetectionResultsView(viewModel: viewModel)
        }
    }
    
    // MARK: - AI Processing Functions
    private func generateAutoCaptions() {
        startAIProcessing(task: "captions")
        viewModel.generateAutoCaption()
    }
    
    private func detectScenes() {
        startAIProcessing(task: "scenes")
        viewModel.detectScenes()
    }
    
    private func removeBackground() {
        startAIProcessing(task: "background")
        viewModel.removeBackground()
    }
    
    private func enhanceAudio() {
        startAIProcessing(task: "audio")
        // Mock audio enhancement
        print("Enhancing audio quality...")
    }
    
    private func smartCrop() {
        startAIProcessing(task: "crop")
        // Mock smart crop
        print("Applying smart crop...")
    }
    
    private func startAIProcessing(task: String) {
        currentAITask = task
        isProcessingAI = true
        aiProgress = 0
        
        // Simulate processing with progress updates
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            aiProgress += 0.05
            if aiProgress >= 1.0 {
                timer.invalidate()
                isProcessingAI = false
                aiProgress = 0
                currentAITask = ""
            }
        }
    }
}

struct AIToolSection: View {
    let title: String
    let systemImage: String
    let description: String
    let isProcessing: Bool
    let progress: Double
    let action: () -> Void
    let settingsAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.accentBlue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let settingsAction = settingsAction {
                        Button(action: settingsAction) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: action) {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "play.fill")
                                .foregroundColor(.accentBlue)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }
            }
            
            if isProcessing {
                ProgressView(value: progress)
                    .tint(.accentBlue)
                    .scaleEffect(y: 0.8)
            }
        }
        .padding()
        .glassCard()
        .hoverEffect()
        .bounceOnTap()
    }
}

struct ExportSection: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingExportSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Export")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button(action: { showingExportSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 8) {
                ExportPresetButton(
                    platform: "YouTube",
                    systemImage: "play.rectangle.fill",
                    preset: ExportPreset.defaultPresets[0],
                    viewModel: viewModel
                )
                
                ExportPresetButton(
                    platform: "Instagram",
                    systemImage: "camera.fill",
                    preset: ExportPreset.defaultPresets[1],
                    viewModel: viewModel
                )
                
                ExportPresetButton(
                    platform: "TikTok",
                    systemImage: "music.note",
                    preset: ExportPreset.defaultPresets[2],
                    viewModel: viewModel
                )
                
                ExportPresetButton(
                    platform: "Custom",
                    systemImage: "slider.horizontal.3",
                    preset: ExportPreset(
                        name: "Custom",
                        settings: ExportSettings(
                            resolution: .hd1080,
                            frameRate: 30,
                            quality: .high,
                            format: .mp4
                        ),
                        platform: .custom
                    ),
                    viewModel: viewModel
                )
            }
            
            if viewModel.isExporting {
                VStack(spacing: 8) {
                    HStack {
                        Text("Exporting...")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.exportProgress * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(.primaryText)
                    }
                    
                    ProgressView(value: viewModel.exportProgress)
                        .tint(.accentOrange)
                }
                .padding()
                .glassCard()
                .slideTransition(direction: .bottom)
            }
        }
        .sheet(isPresented: $showingExportSettings) {
            ExportSettingsView(viewModel: viewModel)
        }
    }
}

struct ExportPresetButton: View {
    let platform: String
    let systemImage: String
    let preset: ExportPreset
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Button(action: {
            viewModel.exportWithPreset(preset)
        }) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.accentOrange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(platform)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Text(preset.description)
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.accentOrange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentOrange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentOrange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isExporting)
    }
}

// MARK: - Settings Views
struct CaptionSettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var language = "English"
    @State private var fontName = "Helvetica"
    @State private var fontSize: Double = 24
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Caption Settings")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Language")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Picker("Language", selection: $language) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("German").tag("German")
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Font")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Picker("Font", selection: $fontName) {
                        Text("Helvetica").tag("Helvetica")
                        Text("Arial").tag("Arial")
                        Text("Times").tag("Times")
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                    
                    VStack {
                        Text("Size: \(Int(fontSize))")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Slider(value: $fontSize, in: 12...48, step: 2)
                            .tint(.accentBlue)
                    }
                    .frame(width: 120)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Apply") {
                    // Apply settings
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
}

struct VoiceoverSettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var voiceType = "Natural"
    @State private var speed: Double = 1.0
    @State private var scriptText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Voiceover")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Voice Type")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Picker("Voice", selection: $voiceType) {
                    Text("Natural").tag("Natural")
                    Text("Professional").tag("Professional")
                    Text("Conversational").tag("Conversational")
                    Text("Dramatic").tag("Dramatic")
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Speed: \(speed, specifier: "%.1f")x")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Slider(value: $speed, in: 0.5...2.0, step: 0.1)
                    .tint(.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Script")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                TextEditor(text: $scriptText)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Generate") {
                    viewModel.generateAIVoiceover(text: scriptText)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
                .disabled(scriptText.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
}

struct SceneDetectionResultsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Scene Detection Results")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
            
            Text("Found 5 scene changes:")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        HStack {
                            Text("Scene \(index + 1)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Text("\(index * 10)s - \((index + 1) * 10)s")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            Button("Split") {
                                // Split at this point
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding()
                        .glassCard()
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Apply All Splits") {
                    // Apply all scene splits
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
}

struct ExportSettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export Settings")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
            
            // Implementation for export settings
            Text("Custom export settings coming soon...")
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Export") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentOrange)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
}

#Preview {
    AIToolsView(viewModel: MainViewModel())
        .frame(width: 350, height: 600)
} 