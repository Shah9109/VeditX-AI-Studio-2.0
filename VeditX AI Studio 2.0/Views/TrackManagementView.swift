import SwiftUI

struct TrackManagementView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrackType: TimelineTrack.TrackType = .video
    @State private var newTrackName = ""
    @State private var showingDeleteConfirmation = false
    @State private var trackToDelete: TimelineTrack?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Track Management")
                    .font(.title2.bold())
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
            }
            
            // Add New Track Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Add New Track")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                HStack(spacing: 16) {
                    // Track Type Selector
                    Picker("Track Type", selection: $selectedTrackType) {
                        ForEach(TimelineTrack.TrackType.allCases, id: \.self) { trackType in
                            HStack {
                                Image(systemName: trackType.icon)
                                Text(trackType.rawValue)
                            }
                            .tag(trackType)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                    
                    // Track Name Input
                    TextField("Track Name", text: $newTrackName)
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            newTrackName = "\(selectedTrackType.rawValue) Track"
                        }
                        .onChange(of: selectedTrackType) { newType in
                            newTrackName = "\(newType.rawValue) Track"
                        }
                    
                    // Add Button
                    Button("Add Track") {
                        addNewTrack()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedTrackType.color)
                    .disabled(newTrackName.isEmpty)
                }
                .padding()
                .glassCard()
            }
            
            // Existing Tracks Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Existing Tracks")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(viewModel.currentProject.timeline.tracks.count) tracks")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.currentProject.timeline.tracks.indices, id: \.self) { index in
                            let track = viewModel.currentProject.timeline.tracks[index]
                            TrackManagementRow(
                                track: track,
                                index: index,
                                onDelete: { 
                                    trackToDelete = track
                                    showingDeleteConfirmation = true
                                },
                                onMoveUp: index > 0 ? { moveTrack(from: index, to: index - 1) } : nil,
                                onMoveDown: index < viewModel.currentProject.timeline.tracks.count - 1 ? { moveTrack(from: index, to: index + 1) } : nil
                            )
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            // Track Statistics
            TrackStatisticsView(tracks: viewModel.currentProject.timeline.tracks)
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 600)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
        .alert("Delete Track", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let track = trackToDelete {
                    viewModel.removeTrack(track.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(trackToDelete?.name ?? "this track")'? This action cannot be undone.")
        }
    }
    
    private func addNewTrack() {
        let newTrack = TimelineTrack(type: selectedTrackType)
        newTrack.name = newTrackName
        viewModel.currentProject.timeline.tracks.append(newTrack)
        
        // Reset form
        newTrackName = "\(selectedTrackType.rawValue) Track"
    }
    
    private func moveTrack(from source: Int, to destination: Int) {
        withAnimation {
            viewModel.currentProject.timeline.tracks.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
        }
    }
}

// MARK: - Track Management Row
struct TrackManagementRow: View {
    @ObservedObject var track: TimelineTrack
    let index: Int
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    @State private var isEditing = false
    @State private var editedName = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Track Order
            Text("\(index + 1)")
                .font(.caption.bold())
                .foregroundColor(.secondaryText)
                .frame(width: 20, alignment: .center)
            
            // Track Icon
            Image(systemName: track.type.icon)
                .foregroundColor(track.type.color)
                .frame(width: 20)
            
            // Track Name
            if isEditing {
                TextField("Track Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        track.name = editedName
                        isEditing = false
                    }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Text("\(track.clips.count) clips • \(track.type.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            // Track Properties
            HStack(spacing: 8) {
                // Visibility
                Button(action: { track.isVisible.toggle() }) {
                    Image(systemName: track.isVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(track.isVisible ? .accentBlue : .secondaryText)
                }
                
                // Lock
                Button(action: { track.isLocked.toggle() }) {
                    Image(systemName: track.isLocked ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(track.isLocked ? .accentOrange : .secondaryText)
                }
                
                // Mute (for audio/video tracks)
                if track.type == .audio || track.type == .video {
                    Button(action: { track.isMuted.toggle() }) {
                        Image(systemName: track.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(track.isMuted ? .red : .secondaryText)
                    }
                }
            }
            .font(.caption)
            
            // Move Controls
            VStack(spacing: 2) {
                if let onMoveUp = onMoveUp {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                if let onMoveDown = onMoveDown {
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            
            // Action Menu
            Menu {
                Button("Rename") {
                    editedName = track.name
                    isEditing = true
                }
                
                Button("Duplicate") {
                    // TODO: Implement track duplication
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(track.type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(track.type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Track Statistics View
struct TrackStatisticsView: View {
    let tracks: [TimelineTrack]
    
    var trackCounts: [TimelineTrack.TrackType: Int] {
        Dictionary(grouping: tracks, by: { $0.type })
            .mapValues { $0.count }
    }
    
    var totalClips: Int {
        tracks.reduce(0) { $0 + $1.clips.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Clips")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text("\(totalClips)")
                        .font(.title3.bold())
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    ForEach(TimelineTrack.TrackType.allCases, id: \.self) { trackType in
                        if let count = trackCounts[trackType], count > 0 {
                            VStack(spacing: 2) {
                                Image(systemName: trackType.icon)
                                    .foregroundColor(trackType.color)
                                    .font(.caption)
                                Text("\(count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.primaryText)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }
}

#Preview {
    TrackManagementView(viewModel: MainViewModel())
} 