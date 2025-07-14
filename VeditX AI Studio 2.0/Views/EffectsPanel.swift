import SwiftUI

struct EffectsPanel: View {
    @ObservedObject var track: TimelineTrack
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: VideoEffect.EffectCategory = .color
    @State private var selectedEffect: VideoEffect?
    @State private var showingEffectPresets = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Effects Panel")
                        .font(.title2.bold())
                        .foregroundColor(.primaryText)
                    
                    Text("Track: \(track.name)")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
            }
            
            HStack(spacing: 16) {
                // Effect Categories
                EffectCategoriesView(selectedCategory: $selectedCategory)
                    .frame(width: 200)
                
                // Available Effects
                EffectLibraryView(
                    category: selectedCategory,
                    track: track,
                    selectedEffect: $selectedEffect
                )
                .frame(width: 300)
                
                // Effect Properties
                if let effect = selectedEffect {
                    EffectPropertiesView(effect: effect)
                        .frame(width: 280)
                }
            }
            
            Divider()
            
            // Applied Effects
            AppliedEffectsView(track: track, selectedEffect: $selectedEffect)
            
            // Effect Presets
            HStack {
                Button("Load Preset") {
                    showingEffectPresets = true
                }
                .buttonStyle(.bordered)
                
                Button("Save Preset") {
                    // TODO: Implement save preset functionality
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Clear All Effects") {
                    track.effects.removeAll()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .disabled(track.effects.isEmpty)
            }
        }
        .padding()
        .frame(width: 900, height: 700)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
        .sheet(isPresented: $showingEffectPresets) {
            EffectPresetsView(track: track)
        }
    }
}

// MARK: - Effect Categories View
struct EffectCategoriesView: View {
    @Binding var selectedCategory: VideoEffect.EffectCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            ForEach(VideoEffect.EffectCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Image(systemName: category.icon)
                            .frame(width: 20)
                        
                        Text(category.rawValue)
                            .font(.system(size: 14))
                        
                        Spacer()
                    }
                    .foregroundColor(selectedCategory == category ? .white : .primaryText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedCategory == category ? Color.accentBlue : Color.clear)
                )
            }
            
            Spacer()
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Effect Library View
struct EffectLibraryView: View {
    let category: VideoEffect.EffectCategory
    @ObservedObject var track: TimelineTrack
    @Binding var selectedEffect: VideoEffect?
    
    var effectsInCategory: [VideoEffect.EffectType] {
        VideoEffect.EffectType.allCases.filter { $0.category == category }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Effects")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(effectsInCategory, id: \.self) { effectType in
                        EffectLibraryItem(
                            effectType: effectType,
                            isApplied: track.effects.contains { $0.type == effectType },
                            onAdd: {
                                let newEffect = VideoEffect(type: effectType)
                                track.effects.append(newEffect)
                                selectedEffect = newEffect
                            },
                            onRemove: {
                                track.effects.removeAll { $0.type == effectType }
                                if selectedEffect?.type == effectType {
                                    selectedEffect = nil
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Effect Library Item
struct EffectLibraryItem: View {
    let effectType: VideoEffect.EffectType
    let isApplied: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(effectType.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text(effectType.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            if isApplied {
                Button("Remove") {
                    onRemove()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .font(.caption)
            } else {
                Button("Add") {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentBlue)
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isApplied ? Color.accentBlue.opacity(0.1) : Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isApplied ? Color.accentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Effect Properties View
struct EffectPropertiesView: View {
    @ObservedObject var effect: VideoEffect
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                // Effect Enabled Toggle
                HStack {
                    Toggle("Enabled", isOn: $effect.isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .accentBlue))
                    
                    Spacer()
                }
                
                // Intensity Slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Text("\(Int(effect.intensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Slider(value: $effect.intensity, in: 0...1)
                        .tint(.accentBlue)
                }
                
                Divider()
                
                // Effect-Specific Parameters
                EffectParametersView(effect: effect)
            }
            
            Spacer()
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Effect Parameters View
struct EffectParametersView: View {
    @ObservedObject var effect: VideoEffect
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameters")
                .font(.subheadline.bold())
                .foregroundColor(.primaryText)
            
            ForEach(Array(effect.parameters.keys.sorted()), id: \.self) { paramKey in
                if let parameter = effect.parameters[paramKey] {
                    ParameterControlView(
                        key: paramKey,
                        parameter: Binding(
                            get: { parameter },
                            set: { effect.parameters[paramKey] = $0 }
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Parameter Control View
struct ParameterControlView: View {
    let key: String
    @Binding var parameter: EffectParameter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key.capitalized)
                .font(.caption)
                .foregroundColor(.primaryText)
            
            if let floatValue = parameter.floatValue {
                HStack {
                    Slider(
                        value: Binding(
                            get: { floatValue },
                            set: { parameter.floatValue = $0 }
                        ),
                        in: parameterRange(for: key)
                    )
                    .tint(.accentBlue)
                    
                    Text(String(format: "%.2f", floatValue))
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .frame(width: 40)
                }
            } else if let boolValue = parameter.boolValue {
                Toggle("", isOn: Binding(
                    get: { boolValue },
                    set: { parameter.boolValue = $0 }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .accentBlue))
            } else if let colorValue = parameter.colorValue {
                ColorPicker("Color", selection: Binding(
                    get: { 
                        Color(.sRGB, red: Double(colorValue[0]), green: Double(colorValue[1]), blue: Double(colorValue[2]), opacity: Double(colorValue[3]))
                    },
                    set: { color in
                        let components = color.cgColor?.components ?? [0, 0, 0, 1]
                        parameter.colorValue = components.map { Float($0) }
                    }
                ))
            }
        }
    }
    
    private func parameterRange(for key: String) -> ClosedRange<Float> {
        switch key.lowercased() {
        case "brightness": return -1.0...1.0
        case "contrast": return 0.0...2.0
        case "saturation": return 0.0...2.0
        case "hue", "angle": return -180.0...180.0
        case "radius": return 0.0...50.0
        case "amount": return 0.0...1.0
        case "intensity": return 0.0...1.0
        default: return 0.0...1.0
        }
    }
}

// MARK: - Applied Effects View
struct AppliedEffectsView: View {
    @ObservedObject var track: TimelineTrack
    @Binding var selectedEffect: VideoEffect?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Applied Effects")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(track.effects.count) effects")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            if track.effects.isEmpty {
                Text("No effects applied")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(track.effects.indices, id: \.self) { index in
                        let effect = track.effects[index]
                        AppliedEffectRow(
                            effect: effect,
                            isSelected: selectedEffect?.id == effect.id,
                            onSelect: { selectedEffect = effect },
                            onRemove: { 
                                track.effects.remove(at: index)
                                if selectedEffect?.id == effect.id {
                                    selectedEffect = nil
                                }
                            },
                            onMoveUp: index > 0 ? {
                                track.effects.move(fromOffsets: IndexSet(integer: index), toOffset: index)
                            } : nil,
                            onMoveDown: index < track.effects.count - 1 ? {
                                track.effects.move(fromOffsets: IndexSet(integer: index), toOffset: index + 2)
                            } : nil
                        )
                    }
                }
            }
        }
        .padding()
        .glassCard()
        .frame(maxHeight: 200)
    }
}

// MARK: - Applied Effect Row
struct AppliedEffectRow: View {
    @ObservedObject var effect: VideoEffect
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Effect Icon
            Image(systemName: effect.type.category.icon)
                .foregroundColor(effect.isEnabled ? .accentBlue : .secondaryText)
                .frame(width: 20)
            
            // Effect Info
            VStack(alignment: .leading, spacing: 2) {
                Text(effect.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(effect.isEnabled ? .primaryText : .secondaryText)
                
                Text("\(Int(effect.intensity * 100))% intensity")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 8) {
                // Enable/Disable
                Button(action: { effect.isEnabled.toggle() }) {
                    Image(systemName: effect.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(effect.isEnabled ? .accentBlue : .secondaryText)
                }
                
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
                
                // Remove
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentBlue.opacity(0.2) : Color.black.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentBlue : Color.clear, lineWidth: 1)
                )
        )
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Effect Presets View
struct EffectPresetsView: View {
    @ObservedObject var track: TimelineTrack
    @Environment(\.dismiss) private var dismiss
    
    let presets = [
        "Cinematic Look",
        "Vintage Film",
        "Black & White",
        "Color Pop",
        "Dream Sequence",
        "Horror Style",
        "Sci-Fi Look",
        "Documentary Style"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Effect Presets")
                    .font(.title2.bold())
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    Button(action: {
                        applyPreset(preset)
                        dismiss()
                    }) {
                        VStack {
                            Image(systemName: "camera.filters")
                                .font(.title2)
                                .foregroundColor(.accentBlue)
                            
                            Text(preset)
                                .font(.caption)
                                .foregroundColor(.primaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
        .glassEffect(cornerRadius: 16, material: .hudWindow)
    }
    
    private func applyPreset(_ presetName: String) {
        track.effects.removeAll()
        
        switch presetName {
        case "Cinematic Look":
            track.effects = [
                VideoEffect(type: .vignette),
                VideoEffect(type: .contrast),
                VideoEffect(type: .saturation)
            ]
        case "Vintage Film":
            track.effects = [
                VideoEffect(type: .sepia),
                VideoEffect(type: .filmGrain),
                VideoEffect(type: .vignette)
            ]
        case "Black & White":
            track.effects = [
                VideoEffect(type: .blackWhite),
                VideoEffect(type: .contrast)
            ]
        default:
            track.effects = [VideoEffect(type: .brightness)]
        }
    }
}

#Preview {
    EffectsPanel(track: TimelineTrack(type: .video), viewModel: MainViewModel())
} 