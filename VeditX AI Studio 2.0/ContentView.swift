//
//  ContentView.swift
//  VeditX AI Studio 2.0
//
//  Created by Sanjay Shah on 14/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Tab Navigation
                TopTabBar(viewModel: viewModel)
                
                // Main Content Area
                HSplitView {
                    // Left Panel - Media Bin
                    MediaBinView(viewModel: viewModel)
                        .frame(minWidth: 250, maxWidth: 350)
                    
                    VSplitView {
                        // Center Panel - Video Preview
                        VideoPreviewView(viewModel: viewModel)
                            .frame(minHeight: 300)
                        
                        // Bottom Panel - Timeline
                        TimelineEditorView(viewModel: viewModel)
                            .frame(minHeight: 200, maxHeight: 300)
                    }
                    
                    // Right Panel - AI Tools & Export
                    AIToolsView(viewModel: viewModel)
                        .frame(minWidth: 280, maxWidth: 350)
                }
                .padding(16)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
    }
}

// MARK: - Top Tab Bar
struct TopTabBar: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // App Title
            HStack {
                Image(systemName: "film.fill")
                    .foregroundColor(.accentOrange)
                Text("VeditX AI Studio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
            
            // Tab Navigation
            HStack(spacing: 12) {
                ForEach(MainViewModel.TabType.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        systemImage: tab.systemImage,
                        isSelected: viewModel.selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    }
                }
            }
            
            Spacer()
            
            // Project Actions
            HStack(spacing: 12) {
                Button("New") {
                    viewModel.newProject()
                }
                .buttonStyle(.plain)
                .foregroundColor(.primaryText)
                
                Button("Save") {
                    viewModel.showingProjectSavePanel = true
                }
                .buttonStyle(.plain)
                .foregroundColor(.primaryText)
                
                Button("Open") {
                    viewModel.showingProjectOpenPanel = true
                }
                .buttonStyle(.plain)
                .foregroundColor(.primaryText)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            VisualEffectView(material: .titlebar)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentBlue.opacity(0.3) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.accentBlue : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(isSelected ? .white : .secondaryText)
        }
        .buttonStyle(.plain)
    }
}

// Note: MediaBinView and VideoPreviewView are now in separate files

struct TimelineView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Mock timeline tracks
            VStack(spacing: 8) {
                TimelineTrackView(name: "basketball.mp4", color: .timelineVideo)
                TimelineTrackView(name: "Voice Over", color: .timelineAudio)
                TimelineTrackView(name: "Subtitle", color: .timelineSubtitle)
            }
            
            Spacer()
        }
        .padding()
        .glassEffect(cornerRadius: 12, material: .hudWindow)
    }
}

struct TimelineTrackView: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            // Track content
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 40)
                
                // Sample clip
                Rectangle()
                    .fill(color.opacity(0.8))
                    .frame(width: 120, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        Text(name.components(separatedBy: ".").first ?? name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .truncationMode(.tail)
                    )
                    .padding(.leading, 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

struct AIToolsPanel: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Tools")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                AIToolButton(
                    title: "Auto Captions",
                    systemImage: "text.bubble.fill",
                    description: "Generate captions automatically"
                ) {
                    viewModel.generateAutoCaption()
                }
                
                AIToolButton(
                    title: "AI Voiceover",
                    systemImage: "mic.fill",
                    description: "Create AI-generated voiceover"
                ) {
                    viewModel.generateAIVoiceover(text: "Sample text")
                }
                
                AIToolButton(
                    title: "Scene Detection",
                    systemImage: "eye.fill",
                    description: "Automatically detect scenes"
                ) {
                    viewModel.detectScenes()
                }
                
                AIToolButton(
                    title: "Background Removal",
                    systemImage: "person.crop.rectangle.fill",
                    description: "Remove video background"
                ) {
                    viewModel.removeBackground()
                }
            }
            
            Spacer()
            
            // Export Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Export")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 8) {
                    ExportButton(platform: "YouTube", systemImage: "play.rectangle.fill")
                    ExportButton(platform: "Instagram", systemImage: "camera.fill")
                    ExportButton(platform: "TikTok", systemImage: "music.note")
                }
            }
        }
        .padding()
        .glassEffect(cornerRadius: 12, material: .sidebar)
    }
}

struct AIToolButton: View {
    let title: String
    let systemImage: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: systemImage)
                            .foregroundColor(.accentBlue)
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryText)
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

struct ExportButton: View {
    let platform: String
    let systemImage: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.accentOrange)
                Text(platform)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                Spacer()
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
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
