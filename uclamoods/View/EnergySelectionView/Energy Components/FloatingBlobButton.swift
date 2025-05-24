//
//  FloatingBlobButton.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI
import FluidGradient

struct FloatingBlobButton: View {
    @State private var controlPoints: [CGPoint]
    @State private var offset = CGSize.zero
    @State private var colorInterpolation: CGFloat = 0
    
    // Text and action
    let text: String
    let action: () -> Void
    
    // Size and appearance
    let size: CGFloat
    let fontSize: CGFloat
    let blurRadius: CGFloat
    
    // Colors
    let startColor: Color
    let endColor: Color
    let useColorAnimation: Bool
    
    // Animation speeds (higher = faster)
    let morphSpeed: Double
    let floatSpeed: Double
    let colorShiftSpeed: Double
    
    // Movement range (0-1, where 1 = full container size)
    let movementRange: CGFloat
    
    let isSelected: Bool
    @State private var glowOpacity: Double = 0.0
    @Binding var isPressing: Bool
    
    // State for FluidGradient
    @State private var colors: [Color] = []
    @State private var highlights: [Color] = []
    @State private var speed: Double = 1.0
    
    var gradient: some View {
        FluidGradient(blobs: colors,
                      highlights: highlights,
                      speed: speed)
    }
    
    var colorPool: [Color] = [Color("Rage"), Color("Euphoric")]
    
    init(
        text: String,
        size: CGFloat = 200,
        fontSize: CGFloat = 20,
        blurRadius: CGFloat = 8,
        startColor: Color? = nil,
        endColor: Color? = nil,
        useColorAnimation: Bool = true,
        morphSpeed: Double = 1.0,
        floatSpeed: Double = 1.0,
        colorShiftSpeed: Double = 1.0,
        movementRange: CGFloat = 0.5,
        colorPool: [Color] = [Color("Rage"), Color("Euphoric")],
        isSelected: Bool = false,
        isPressing: Binding<Bool> = .constant(false),
        
        action: @escaping () -> Void
    ) {
        self.text = text
        self.action = action
        self.size = size
        self.fontSize = fontSize
        self.blurRadius = blurRadius
        self.useColorAnimation = useColorAnimation
        self.morphSpeed = morphSpeed
        self.floatSpeed = floatSpeed
        self.colorShiftSpeed = colorShiftSpeed
        self.movementRange = min(max(movementRange, 0), 1) // Clamp between 0 and 1
        
        // Use provided colors or generate default gradient colors
        if let start = startColor, let end = endColor {
            self.startColor = start
            self.endColor = end
        } else {
            // Default colors if none provided
            let baseHue = Double.random(in: 0...1)
            self.startColor = Color(hue: baseHue, saturation: 0.8, brightness: 0.9)
            self.endColor = Color(hue: baseHue + 0.2, saturation: 0.8, brightness: 0.9)
        }
        
        self.colorPool = colorPool
        
        // Initialize with random control points
        _controlPoints = State(initialValue: (0..<8).map { _ in
            CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
        })
        self.isSelected = isSelected
        self._isPressing = isPressing
    }
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                ZStack {
                    if isSelected {
                        gradient
                            .backgroundStyle(.quaternary)
                            .mask(
                                BlobShape(controlPoints: controlPoints)
                                    .scaleEffect(1.4 * (isPressing ? 0.95 : 1.0))
                            )
                            .blur(radius: 20)
                            .opacity(glowOpacity)
                            .offset(y: 10) // Similar to padding top
                    }
                    
                    gradient
                        .backgroundStyle(.quaternary)
                        .blur(radius: 5)
                        .mask(
                            BlobShape(controlPoints: controlPoints)
                        )
                        .blur(radius: isSelected ? 8 : 8)
                        .scaleEffect((isSelected ? 1.15 : 1.0) * (isPressing ? 0.95 : 1.0))
                        .shadow(
                            color: colorPool.first?.opacity(0.6) ?? Color.clear,
                            radius: isSelected ? 10 : 3,
                            x: 0,
                            y: isSelected ? 5 : 2
                        )
                    // Text overlay
                    Text(text)
                        .font(.custom("Georgia", size: isSelected ? 24 : fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(4)
                        .scaleEffect((isSelected ? 1.0 : 0.9) * (isPressing ? 0.95 : 1.0))
                        .opacity(isSelected ? 1.0 : 1.0)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    
                    
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)
                .onAppear {
                    startAnimations(in: geometry.size)
                    setColors()
                    if isSelected {
                        startGlowAnimation()
                    }
                }
                .onChange(of: isSelected) { newValue in
                    if newValue {
                        startGlowAnimation()
                    } else {
                        glowOpacity = 0.0
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: size, height: size)
    }
    
    private func startGlowAnimation() {
        // Reset to start state
        glowOpacity = 0.0
        
        // Start the continuous pulsing animation
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.5
        }
    }
    
    
    func setColors() {
        colors = []
        highlights = [.white]
        for _ in 0...Int.random(in: 5...5) {
            colors.append(colorPool.randomElement()!)
        }
        for _ in 0...Int.random(in: 5...5) {
            highlights.append(colorPool.randomElement()!)
        }
    }
    
    // Color interpolation function similar to EmotionDataProvider
    private func interpolateColor(startColor: Color, endColor: Color, fraction: CGFloat) -> Color {
        // Extract components using UIColor
        let startUIColor = UIColor(startColor)
        let endUIColor = UIColor(endColor)
        
        var startRed: CGFloat = 0
        var startGreen: CGFloat = 0
        var startBlue: CGFloat = 0
        var startAlpha: CGFloat = 0
        
        var endRed: CGFloat = 0
        var endGreen: CGFloat = 0
        var endBlue: CGFloat = 0
        var endAlpha: CGFloat = 0
        
        startUIColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endUIColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
        
        // Interpolate
        let r = startRed + (endRed - startRed) * fraction
        let g = startGreen + (endGreen - startGreen) * fraction
        let b = startBlue + (endBlue - startBlue) * fraction
        let a = startAlpha + (endAlpha - startAlpha) * fraction
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
    
    private func startAnimations(in size: CGSize) {
        // Calculate animation durations based on speed parameters (higher speed = lower duration)
        let baseMorphDuration = 3.5 / morphSpeed
        let baseFloatDuration = 5.0 / floatSpeed
        let baseColorDuration = 10.0 / colorShiftSpeed
        
        // Randomize slightly around the base to create natural variation
        let morphDuration = Double.random(in: baseMorphDuration * 0.8...baseMorphDuration * 1.2)
        let floatDuration = Double.random(in: baseFloatDuration * 0.8...baseFloatDuration * 1.2)
        let colorDuration = Double.random(in: baseColorDuration * 0.8...baseColorDuration * 1.2)
        
        // Animate blob shape
        withAnimation(.easeInOut(duration: morphDuration).repeatForever(autoreverses: true)) {
            controlPoints = (0..<5).map { _ in
                CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
            }
        }
        
        // Calculate movement constraints
        let maxX = size.width - self.size
        let maxY = size.height - self.size
        
        // Animate floating motion
        withAnimation(.easeInOut(duration: floatDuration).repeatForever(autoreverses: true)) {
            offset = CGSize(
                width: CGFloat.random(in: -maxX * movementRange...maxX * movementRange),
                height: CGFloat.random(in: -maxY * movementRange...maxY * movementRange)
            )
        }
        
        // Animate color interpolation if enabled
        if useColorAnimation {
            withAnimation(.easeInOut(duration: colorDuration).repeatForever(autoreverses: true)) {
                colorInterpolation = 1.0
            }
        }
    }
}

struct FloatingBlobButton_Preview: PreviewProvider {
    static var previews: some View {
        FloatingBlobButton(text: "Test", action: {
            
        })
        //.background(Color.black.opacity(0.1))
        .previewLayout(.sizeThatFits)
        .padding()
        .preferredColorScheme(.dark)
    }
}
