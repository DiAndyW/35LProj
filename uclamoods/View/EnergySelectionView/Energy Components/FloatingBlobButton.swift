//
//  FloatingBlobButton.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

struct FloatingBlobButton: View {
    @State private var controlPoints: [CGPoint]
    @State private var offset = CGSize.zero
    @State private var colorInterpolation: CGFloat = 0
    
    // Text and action
    let text: String
    let action: () -> Void
    
    // Size and appearance
    let size: CGFloat
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
    
    init(
        text: String,
        size: CGFloat = 180,
        blurRadius: CGFloat = 5,
        startColor: Color? = nil,
        endColor: Color? = nil,
        useColorAnimation: Bool = true,
        morphSpeed: Double = 1.0,
        floatSpeed: Double = 1.0,
        colorShiftSpeed: Double = 1.0,
        movementRange: CGFloat = 0.5,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.action = action
        self.size = size
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
        
        // Initialize with random control points
        _controlPoints = State(initialValue: (0..<8).map { _ in
            CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
        })
    }
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                ZStack {
                    // Blob background
                    BlobShape(controlPoints: controlPoints)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    interpolateColor(startColor: startColor, endColor: endColor, fraction: colorInterpolation),
                                    interpolateColor(startColor: startColor, endColor: endColor, fraction: min(colorInterpolation + 0.3, 1.0))
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: blurRadius)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .offset(offset)
                    
                    // Text overlay
                    Text(text)
                        .font(.custom("Georgia", size: 24))
                        //.blur(radius: 0.4)
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                        
                }
                .onAppear {
                    startAnimations(in: geometry.size)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: size, height: size)
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
            controlPoints = (0..<8).map { _ in
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
