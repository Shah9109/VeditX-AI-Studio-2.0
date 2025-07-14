import SwiftUI

// MARK: - Animation Extensions
extension View {
    /// Smooth slide transition for views
    func slideTransition(direction: Edge = .leading, duration: Double = 0.3) -> some View {
        transition(
            .asymmetric(
                insertion: .move(edge: direction).combined(with: .opacity),
                removal: .move(edge: direction.opposite).combined(with: .opacity)
            )
            .animation(.easeInOut(duration: duration))
        )
    }
    
    /// Smooth scale transition for buttons and cards
    func scaleTransition(scale: CGFloat = 0.8, duration: Double = 0.2) -> some View {
        transition(
            .scale(scale: scale)
            .combined(with: .opacity)
            .animation(.spring(response: duration, dampingFraction: 0.8))
        )
    }
    
    /// Smooth hover effects
    func hoverEffect(scale: CGFloat = 1.05, brightness: Double = 0.1) -> some View {
        modifier(HoverEffectModifier(scale: scale, brightness: brightness))
    }
    
    /// Smooth loading shimmer effect
    func shimmerEffect(isActive: Bool = true) -> some View {
        modifier(ShimmerEffectModifier(isActive: isActive))
    }
    
    /// Smooth bounce animation for interactive elements
    func bounceOnTap() -> some View {
        modifier(BounceOnTapModifier())
    }
    
    /// Smooth glow effect for important elements
    func glowEffect(color: Color = .accentBlue, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowEffectModifier(color: color, radius: radius, isActive: isActive))
    }
}

// MARK: - Edge Extension
extension Edge {
    var opposite: Edge {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}

// MARK: - Custom View Modifiers
struct HoverEffectModifier: ViewModifier {
    let scale: CGFloat
    let brightness: Double
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .brightness(isHovered ? brightness : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct ShimmerEffectModifier: ViewModifier {
    let isActive: Bool
    @State private var shimmerOffset: CGFloat = -200
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .opacity(isActive ? 1 : 0)
                    .allowsHitTesting(false)
            )
            .clipped()
            .onAppear {
                if isActive {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        shimmerOffset = 200
                    }
                }
            }
    }
}

struct BounceOnTapModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

struct GlowEffectModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    @State private var glowIntensity: Double = 0.5
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(glowIntensity) : .clear, radius: radius)
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowIntensity = 1.0
                    }
                }
            }
    }
}

// MARK: - Animated Progress Views
struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    let backgroundColor: Color
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(
        progress: Double,
        color: Color = .accentBlue,
        backgroundColor: Color = Color.black.opacity(0.3),
        height: CGFloat = 8,
        cornerRadius: CGFloat = 4
    ) {
        self.progress = progress
        self.color = color
        self.backgroundColor = backgroundColor
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)
                    .cornerRadius(cornerRadius)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: height)
                    .cornerRadius(cornerRadius)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct PulsingCircle: View {
    let color: Color
    let size: CGFloat
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                    opacity = 0.3
                }
            }
    }
}

// MARK: - Animated Text Effects
struct TypewriterText: View {
    let text: String
    let speed: Double
    @State private var displayedText = ""
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                animateText()
            }
            .onChange(of: text) { _ in
                displayedText = ""
                animateText()
            }
    }
    
    private func animateText() {
        for (index, character) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * speed) {
                displayedText += String(character)
            }
        }
    }
}

struct FadeInText: View {
    let text: String
    let delay: Double
    @State private var opacity: Double = 0
    
    var body: some View {
        Text(text)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Custom Loading Indicators
struct CircularLoadingIndicator: View {
    let size: CGFloat
    let color: Color
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [color.opacity(0.2), color],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

struct WaveLoadingIndicator: View {
    let color: Color
    @State private var phase: Double = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(
                        1 + 0.5 * sin(phase + Double(index) * 0.5)
                    )
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.1),
                        value: phase
                    )
            }
        }
        .onAppear {
            phase = .pi * 2
        }
    }
}

// MARK: - Smooth Transitions for Navigation
struct SlideTransition: ViewModifier {
    let isPresented: Bool
    let edge: Edge
    
    func body(content: Content) -> some View {
        content
            .transition(.move(edge: edge).combined(with: .opacity))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Animated Containers
struct AnimatedCard: View {
    let content: AnyView
    @State private var isVisible = false
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
    }
} 