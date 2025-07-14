import SwiftUI
import CoreText

struct TextEditorView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: TextEditorTab = .content
    @State private var textContent = "Sample Text"
    @State private var textStyle = TextStyle()
    @State private var textAnimation = TextAnimation()
    @State private var previewSize = CGSize(width: 300, height: 200)
    
    enum TextEditorTab: String, CaseIterable {
        case content = "Content"
        case style = "Style"
        case animation = "Animation"
        case position = "Position"
        
        var icon: String {
            switch self {
            case .content: return "text.cursor"
            case .style: return "textformat"
            case .animation: return "play.circle"
            case .position: return "move.3d"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            TextEditorHeader(onDismiss: { dismiss() })
            
            HStack(spacing: 20) {
                // Preview Panel
                TextPreviewPanel(
                    textContent: textContent,
                    textStyle: textStyle,
                    textAnimation: textAnimation,
                    previewSize: $previewSize
                )
                .frame(width: 400)
                
                Divider()
                
                // Editor Panel
                VStack(alignment: .leading, spacing: 16) {
                    // Tab Selector
                    TextEditorTabSelector(selectedTab: $selectedTab)
                    
                    // Editor Content
                    ScrollView {
                        switch selectedTab {
                        case .content:
                            TextContentEditor(textContent: $textContent)
                        case .style:
                            TextStyleEditor(textStyle: $textStyle)
                        case .animation:
                            TextAnimationEditor(textAnimation: $textAnimation)
                        case .position:
                            TextPositionEditor(textStyle: $textStyle)
                        }
                    }
                    .frame(maxHeight: 400)
                }
                .frame(width: 350)
            }
            
            // Bottom Actions
            HStack {
                Button("Text Presets") {
                    // Show text presets
                }
                .buttonStyle(.bordered)
                
                Button("Import Font") {
                    // Import custom font
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add to Timeline") {
                    addTextToTimeline()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 800, height: 600)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
    
    private func addTextToTimeline() {
        // Create text clip and add to timeline
        // This would involve creating a special text media item
    }
}

// MARK: - Text Editor Header
struct TextEditorHeader: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Text Editor")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentBlue)
        }
    }
}

// MARK: - Tab Selector
struct TextEditorTabSelector: View {
    @Binding var selectedTab: TextEditorView.TextEditorTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TextEditorView.TextEditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTab == tab ? Color.accentBlue : Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

// MARK: - Text Preview Panel
struct TextPreviewPanel: View {
    let textContent: String
    let textStyle: TextStyle
    let textAnimation: TextAnimation
    @Binding var previewSize: CGSize
    @State private var animationOffset: CGFloat = 0
    @State private var animationOpacity: Double = 1.0
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(Int(previewSize.width))×\(Int(previewSize.height))")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            // Preview Canvas
            ZStack {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: previewSize.width, height: previewSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Text Rendering
                Text(textContent.isEmpty ? "Sample Text" : textContent)
                    .font(textStyle.swiftUIFont)
                    .foregroundColor(textStyle.textColor)
                    .multilineTextAlignment(textStyle.alignment.textAlignment)
                    .shadow(
                        color: textStyle.shadowColor,
                        radius: textStyle.shadowBlur,
                        x: textStyle.shadowOffset.width,
                        y: textStyle.shadowOffset.height
                    )
                    .background(
                        RoundedRectangle(cornerRadius: textStyle.backgroundCornerRadius)
                            .fill(textStyle.backgroundColor)
                            .padding(-textStyle.backgroundPadding)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: textStyle.backgroundCornerRadius)
                            .stroke(textStyle.borderColor, lineWidth: textStyle.borderWidth)
                            .padding(-textStyle.backgroundPadding)
                    )
                    .scaleEffect(animationScale)
                    .opacity(animationOpacity)
                    .offset(x: animationOffset, y: 0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationOffset)
            }
            
            // Size Controls
            VStack(spacing: 8) {
                HStack {
                    Text("Canvas Size")
                        .font(.caption)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Button("16:9") {
                        previewSize = CGSize(width: 320, height: 180)
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                    
                    Button("9:16") {
                        previewSize = CGSize(width: 180, height: 320)
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                    
                    Button("1:1") {
                        previewSize = CGSize(width: 250, height: 250)
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Text("W:")
                        .font(.caption)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { previewSize.width },
                        set: { previewSize.width = $0 }
                    ), in: 200...500)
                    .tint(.accentBlue)
                }
                
                HStack {
                    Text("H:")
                        .font(.caption)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { previewSize.height },
                        set: { previewSize.height = $0 }
                    ), in: 150...400)
                    .tint(.accentBlue)
                }
            }
        }
        .padding()
        .glassCard()
        .onAppear {
            startPreviewAnimation()
        }
    }
    
    private func startPreviewAnimation() {
        switch textAnimation.type {
        case .slideIn:
            animationOffset = -50
        case .fadeIn:
            animationOpacity = 0
        case .scale:
            animationScale = 0.5
        default:
            break
        }
    }
}

// MARK: - Text Content Editor
struct TextContentEditor: View {
    @Binding var textContent: String
    @State private var showingTemplates = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Content")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Text Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Text")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                TextEditor(text: $textContent)
                    .font(.system(size: 14))
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentBlue.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding()
            .glassCard()
            
            // Text Templates
            VStack(alignment: .leading, spacing: 8) {
                Text("Templates")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(TextTemplate.allTemplates, id: \.title) { template in
                        Button(action: {
                            textContent = template.content
                        }) {
                            VStack {
                                Image(systemName: template.icon)
                                    .font(.title3)
                                    .foregroundColor(.accentBlue)
                                
                                Text(template.title)
                                    .font(.caption)
                                    .foregroundColor(.primaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .glassCard()
        }
    }
}

// MARK: - Text Style Editor
struct TextStyleEditor: View {
    @Binding var textStyle: TextStyle
    @State private var showingFontPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Style")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Font Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Font")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Button(action: { showingFontPicker = true }) {
                        HStack {
                            Text(textStyle.fontName)
                                .font(.system(size: 14))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Font Size
                HStack {
                    Text("Size:")
                        .font(.caption)
                        .frame(width: 40, alignment: .leading)
                    
                    Slider(value: $textStyle.fontSize, in: 12...72)
                        .tint(.accentBlue)
                    
                    Text("\(Int(textStyle.fontSize))")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                // Font Weight
                HStack {
                    Text("Weight:")
                        .font(.caption)
                        .frame(width: 40, alignment: .leading)
                    
                    Picker("Weight", selection: $textStyle.fontWeight) {
                        ForEach(TextStyle.FontWeight.allCases, id: \.self) { weight in
                            Text(weight.rawValue).tag(weight)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding()
            .glassCard()
            
            // Colors
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    VStack {
                        Text("Text")
                            .font(.caption)
                        ColorPicker("", selection: $textStyle.textColor)
                            .frame(width: 40, height: 40)
                    }
                    
                    VStack {
                        Text("Background")
                            .font(.caption)
                        ColorPicker("", selection: $textStyle.backgroundColor)
                            .frame(width: 40, height: 40)
                    }
                    
                    VStack {
                        Text("Border")
                            .font(.caption)
                        ColorPicker("", selection: $textStyle.borderColor)
                            .frame(width: 40, height: 40)
                    }
                    
                    VStack {
                        Text("Shadow")
                            .font(.caption)
                        ColorPicker("", selection: $textStyle.shadowColor)
                            .frame(width: 40, height: 40)
                    }
                    
                    Spacer()
                }
                
                // Background Opacity
                HStack {
                    Text("Background Opacity:")
                        .font(.caption)
                    
                    Slider(value: .constant(0.7), in: 0...1)
                        .tint(.accentBlue)
                    
                    Text("70%")
                        .font(.caption)
                        .frame(width: 30)
                }
            }
            .padding()
            .glassCard()
            
            // Effects
            VStack(alignment: .leading, spacing: 8) {
                Text("Effects")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                // Border Width
                HStack {
                    Text("Border:")
                        .font(.caption)
                        .frame(width: 50, alignment: .leading)
                    
                    Slider(value: $textStyle.borderWidth, in: 0...10)
                        .tint(.accentBlue)
                    
                    Text("\(Int(textStyle.borderWidth))")
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Shadow Blur
                HStack {
                    Text("Shadow:")
                        .font(.caption)
                        .frame(width: 50, alignment: .leading)
                    
                    Slider(value: $textStyle.shadowBlur, in: 0...20)
                        .tint(.accentBlue)
                    
                    Text("\(Int(textStyle.shadowBlur))")
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Shadow Offset
                HStack {
                    Text("Offset X:")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { textStyle.shadowOffset.width },
                        set: { textStyle.shadowOffset.width = $0 }
                    ), in: -20...20)
                    .tint(.accentBlue)
                }
                
                HStack {
                    Text("Offset Y:")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { textStyle.shadowOffset.height },
                        set: { textStyle.shadowOffset.height = $0 }
                    ), in: -20...20)
                    .tint(.accentBlue)
                }
            }
            .padding()
            .glassCard()
        }
        .sheet(isPresented: $showingFontPicker) {
            FontPickerView(selectedFont: $textStyle.fontName)
        }
    }
}

// MARK: - Text Animation Editor
struct TextAnimationEditor: View {
    @Binding var textAnimation: TextAnimation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Animation")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Animation Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Animation Type")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                Picker("Type", selection: $textAnimation.type) {
                    ForEach(TextAnimation.AnimationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .glassCard()
            
            // Animation Properties
            VStack(alignment: .leading, spacing: 8) {
                Text("Properties")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text("Duration:")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    Slider(value: $textAnimation.duration, in: 0.1...5.0)
                        .tint(.accentBlue)
                    
                    Text("\(textAnimation.duration, specifier: "%.1f")s")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Delay:")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    Slider(value: $textAnimation.delay, in: 0...3.0)
                        .tint(.accentBlue)
                    
                    Text("\(textAnimation.delay, specifier: "%.1f")s")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                Toggle("Loop", isOn: $textAnimation.loop)
                    .toggleStyle(SwitchToggleStyle(tint: .accentBlue))
            }
            .padding()
            .glassCard()
        }
    }
}

// MARK: - Text Position Editor
struct TextPositionEditor: View {
    @Binding var textStyle: TextStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Position & Layout")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            // Alignment
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Alignment")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    ForEach(TextStyle.TextAlignment.allCases, id: \.self) { alignment in
                        Button(action: {
                            textStyle.alignment = alignment
                        }) {
                            Image(systemName: alignment.icon)
                                .foregroundColor(textStyle.alignment == alignment ? .white : .secondaryText)
                                .frame(width: 30, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(textStyle.alignment == alignment ? Color.accentBlue : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .glassCard()
            
            // Position on Screen
            VStack(alignment: .leading, spacing: 8) {
                Text("Screen Position")
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text("X:")
                        .font(.caption)
                        .frame(width: 20)
                    
                    Slider(value: $textStyle.position.x, in: 0...1)
                        .tint(.accentBlue)
                    
                    Text("\(Int(textStyle.position.x * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Y:")
                        .font(.caption)
                        .frame(width: 20)
                    
                    Slider(value: $textStyle.position.y, in: 0...1)
                        .tint(.accentBlue)
                    
                    Text("\(Int(textStyle.position.y * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                // Quick Position Presets
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(TextPositionPreset.allPresets, id: \.name) { preset in
                        Button(preset.name) {
                            textStyle.position = preset.position
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .glassCard()
        }
    }
}

// MARK: - Supporting Models
struct TextStyle {
    var fontName: String = "Helvetica-Bold"
    var fontSize: CGFloat = 24
    var fontWeight: FontWeight = .bold
    var textColor: Color = .white
    var backgroundColor: Color = .clear
    var borderColor: Color = .clear
    var borderWidth: CGFloat = 0
    var shadowColor: Color = .black.opacity(0.5)
    var shadowOffset: CGSize = CGSize(width: 2, height: 2)
    var shadowBlur: CGFloat = 4
    var alignment: TextAlignment = .center
    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var backgroundPadding: CGFloat = 8
    var backgroundCornerRadius: CGFloat = 4
    
    enum FontWeight: String, CaseIterable {
        case thin = "Thin"
        case light = "Light"
        case regular = "Regular"
        case medium = "Medium"
        case semibold = "Semibold"
        case bold = "Bold"
        case heavy = "Heavy"
        case black = "Black"
        
        var fontWeight: Font.Weight {
            switch self {
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            }
        }
    }
    
    enum TextAlignment: String, CaseIterable {
        case left = "Left"
        case center = "Center"
        case right = "Right"
        
        var textAlignment: SwiftUI.TextAlignment {
            switch self {
            case .left: return .leading
            case .center: return .center
            case .right: return .trailing
            }
        }
        
        var icon: String {
            switch self {
            case .left: return "text.alignleft"
            case .center: return "text.aligncenter"
            case .right: return "text.alignright"
            }
        }
    }
    
    var swiftUIFont: Font {
        return .custom(fontName, size: fontSize).weight(fontWeight.fontWeight)
    }
}

struct TextAnimation {
    var type: AnimationType = .none
    var duration: TimeInterval = 1.0
    var delay: TimeInterval = 0.0
    var loop: Bool = false
    
    enum AnimationType: String, CaseIterable {
        case none = "None"
        case fadeIn = "Fade In"
        case slideIn = "Slide In"
        case slideUp = "Slide Up"
        case scale = "Scale"
        case typewriter = "Typewriter"
        case bounce = "Bounce"
        case rotate = "Rotate"
        case glow = "Glow"
    }
}

struct TextTemplate {
    let title: String
    let content: String
    let icon: String
    
    static let allTemplates = [
        TextTemplate(title: "Title", content: "Your Title Here", icon: "textformat.size.larger"),
        TextTemplate(title: "Subtitle", content: "Your subtitle goes here", icon: "textformat.size"),
        TextTemplate(title: "Call to Action", content: "SUBSCRIBE NOW!", icon: "exclamationmark.triangle"),
        TextTemplate(title: "Question", content: "What do you think?", icon: "questionmark.circle"),
        TextTemplate(title: "Social Media", content: "@YourHandle", icon: "at"),
        TextTemplate(title: "Location", content: "Location Name", icon: "location"),
        TextTemplate(title: "Date/Time", content: "Today, 3:00 PM", icon: "clock"),
        TextTemplate(title: "Quote", content: "\"Amazing quote here\"", icon: "quote.bubble")
    ]
}

struct TextPositionPreset {
    let name: String
    let position: CGPoint
    
    static let allPresets = [
        TextPositionPreset(name: "Top Left", position: CGPoint(x: 0.1, y: 0.1)),
        TextPositionPreset(name: "Top Center", position: CGPoint(x: 0.5, y: 0.1)),
        TextPositionPreset(name: "Top Right", position: CGPoint(x: 0.9, y: 0.1)),
        TextPositionPreset(name: "Center Left", position: CGPoint(x: 0.1, y: 0.5)),
        TextPositionPreset(name: "Center", position: CGPoint(x: 0.5, y: 0.5)),
        TextPositionPreset(name: "Center Right", position: CGPoint(x: 0.9, y: 0.5)),
        TextPositionPreset(name: "Bottom Left", position: CGPoint(x: 0.1, y: 0.9)),
        TextPositionPreset(name: "Bottom Center", position: CGPoint(x: 0.5, y: 0.9)),
        TextPositionPreset(name: "Bottom Right", position: CGPoint(x: 0.9, y: 0.9))
    ]
}

// MARK: - Font Picker View
struct FontPickerView: View {
    @Binding var selectedFont: String
    @Environment(\.dismiss) private var dismiss
    
    let systemFonts = [
        "Helvetica", "Helvetica-Bold", "Arial", "Arial-Bold",
        "Times New Roman", "Times-Bold", "Courier", "Courier-Bold",
        "Georgia", "Georgia-Bold", "Verdana", "Verdana-Bold",
        "Trebuchet MS", "Impact", "Comic Sans MS",
        "Palatino", "Optima", "Futura", "Avenir", "Menlo"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Select Font")
                    .font(.title2.bold())
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(systemFonts, id: \.self) { fontName in
                        Button(action: {
                            selectedFont = fontName
                        }) {
                            HStack {
                                Text("Sample Text")
                                    .font(.custom(fontName, size: 16))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Text(fontName)
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                
                                if selectedFont == fontName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentBlue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedFont == fontName ? Color.accentBlue.opacity(0.2) : Color.black.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
}

#Preview {
    TextEditorView(viewModel: MainViewModel())
} 