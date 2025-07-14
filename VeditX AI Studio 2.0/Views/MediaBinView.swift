import SwiftUI
import AppKit
import AVFoundation

// MARK: - Media Bin View
struct MediaBinView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var dragOver = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Media Bin")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button(action: { importMedia() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                }
                .buttonStyle(.plain)
                .help("Import Media")
            }
            
            // Import area or media grid
            if viewModel.currentProject.mediaItems.isEmpty {
                EmptyMediaBinView { importMedia() }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(dragOver ? Color.accentBlue.opacity(0.1) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        dragOver ? Color.accentBlue : Color.white.opacity(0.2),
                                        style: StrokeStyle(lineWidth: 2, dash: [5])
                                    )
                            )
                    )
                    .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                        handleDrop(providers: providers)
                    }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 12)
                    ], spacing: 12) {
                        ForEach(viewModel.currentProject.mediaItems) { mediaItem in
                            MediaItemView(
                                mediaItem: mediaItem,
                                isSelected: viewModel.selectedMediaItems.contains(mediaItem.id)
                            ) {
                                viewModel.selectMediaItem(mediaItem.id)
                            } onDoubleClick: {
                                addToTimeline(mediaItem)
                            } onDelete: {
                                viewModel.removeMediaItem(withId: mediaItem.id)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(dragOver ? Color.accentBlue.opacity(0.05) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    dragOver ? Color.accentBlue : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                    handleDrop(providers: providers)
                }
            }
            
            Spacer()
        }
        .padding()
        .glassEffect(cornerRadius: 12, material: .sidebar)
    }
    
    private func importMedia() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .movie, .audio, .image,
            .mpeg4Movie, .quickTimeMovie,
            .mp3, .wav, .aiff,
            .jpeg, .png, .tiff, .gif, .heic
        ]
        
        if panel.runModal() == .OK {
            viewModel.importMedia(from: panel.urls)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                        
                        if urls.count == providers.count {
                            DispatchQueue.main.async {
                                viewModel.importMedia(from: urls)
                            }
                        }
                    }
                }
            }
        }
        
        return !providers.isEmpty
    }
    
    private func addToTimeline(_ mediaItem: MediaItem) {
        // Add to appropriate track based on media type
        let trackIndex: Int
        switch mediaItem.type {
        case .video:
            trackIndex = 0 // Video track
        case .audio:
            trackIndex = 1 // Audio track
        case .image:
            trackIndex = 0 // Video track for images
        }
        
        viewModel.addClipToTimeline(
            mediaItem,
            at: viewModel.currentProject.timeline.duration,
            trackIndex: trackIndex
        )
    }
}

// MARK: - Empty Media Bin View
struct EmptyMediaBinView: View {
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)
            
            VStack(spacing: 8) {
                Text("Import Media")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text("Drag & drop files here or click to browse")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Browse Files") {
                onImport()
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentBlue)
            .padding(.horizontal, 20)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            onImport()
        }
    }
}

// MARK: - Media Item View
struct MediaItemView: View {
    let mediaItem: MediaItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void
    let onDelete: () -> Void
    
    @State private var thumbnailImage: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            Group {
                if let thumbnailImage = thumbnailImage {
                    Image(nsImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                        
                        Image(systemName: mediaItem.type.systemImage)
                            .font(.system(size: 24))
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .frame(width: 120, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                // Selection overlay
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.accentBlue : (isHovered ? Color.white.opacity(0.3) : Color.clear),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .overlay(
                // Duration badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(mediaItem.duration.shortFormattedTime)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                    }
                }
            )
            .overlay(
                // Delete button (on hover)
                VStack {
                    HStack {
                        Spacer()
                        if isHovered {
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                    .background(Color.white, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                        }
                    }
                    Spacer()
                }
            )
            
            // File name
            Text(mediaItem.name)
                .font(.caption)
                .foregroundColor(.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .contextMenu {
            Button("Add to Timeline") {
                onDoubleClick()
            }
            
            Divider()
            
            Button("Delete") {
                onDelete()
            }
        }
    }
    
    private func loadThumbnail() {
        if let thumbnailData = mediaItem.thumbnailData,
           let image = NSImage(data: thumbnailData) {
            self.thumbnailImage = image
            return
        }
        
        // Generate thumbnail for different media types
        switch mediaItem.type {
        case .video:
            generateVideoThumbnail()
        case .image:
            loadImageThumbnail()
        case .audio:
            // Use a default audio waveform image
            thumbnailImage = createWaveformThumbnail()
        }
    }
    
    private func generateVideoThumbnail() {
        let asset = AVURLAsset(url: mediaItem.url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 240, height: 160)
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 60)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            guard let image = image else { return }
            
            DispatchQueue.main.async {
                self.thumbnailImage = NSImage(cgImage: image, size: .thumbnailSize)
            }
        }
    }
    
    private func loadImageThumbnail() {
        guard let image = NSImage(contentsOf: mediaItem.url) else { return }
        
        let targetSize = CGSize.thumbnailSize
        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height
        
        let newSize: CGSize
        if aspectRatio > targetSize.width / targetSize.height {
            newSize = CGSize(width: targetSize.width, height: targetSize.width / aspectRatio)
        } else {
            newSize = CGSize(width: targetSize.height * aspectRatio, height: targetSize.height)
        }
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        self.thumbnailImage = resizedImage
    }
    
    private func createWaveformThumbnail() -> NSImage {
        let size = CGSize.thumbnailSize
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw a simple waveform pattern
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
        
        let barWidth: CGFloat = 3
        let spacing: CGFloat = 2
        let maxHeight = size.height * 0.8
        
        var x: CGFloat = spacing
        while x < size.width - barWidth {
            let height = CGFloat.random(in: maxHeight * 0.2...maxHeight)
            let y = (size.height - height) / 2
            
            let rect = CGRect(x: x, y: y, width: barWidth, height: height)
            context?.fill(rect)
            
            x += barWidth + spacing
        }
        
        image.unlockFocus()
        return image
    }
}

#Preview {
    MediaBinView(viewModel: MainViewModel())
        .frame(width: 300, height: 600)
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
} 