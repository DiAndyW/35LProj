//
//  UnifiedAnimations.swift
//  uclamoods
//
//  Created on 5/8/25.
//

import SwiftUI

/// Centralized animation style system for the Mood app
struct MoodAnimations {
    /// Applies the specified transition style to a view
    struct TransitionModifier: ViewModifier {
        let style: TransitionStyle
        let progress: CGFloat // 0 = fully visible, 1 = fully invisible
        let originPoint: CGPoint
        let screenSize: CGSize
        
        func body(content: Content) -> some View {
            // Apply transformations based on the style
            switch style {
            case .fadeScale:
                content
                    .scaleEffect(1.0 - (0.2 * progress))
                    .opacity(1.0 - progress)
            
            case .zoomSlide:
                content
                    .scaleEffect(1.0 - (0.15 * progress))
                    .opacity(1.0 - progress)
                    .offset(x: progress * 50, y: 0)
            
            case .bubbleExpand:
                content
                    .mask(
                        BubbleExpandMask(
                            progress: progress,
                            origin: originPoint,
                            size: screenSize
                        )
                    )
                
            case .revealMask:
                content
                    .opacity(1.0 - (progress * 0.5))
                    .scaleEffect(1.0 - (0.1 * progress), anchor: .top)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .black,
                                .black.opacity(1.0 - progress),
                                .black.opacity(0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
            case .moodMorph:
                content
                    .scaleEffect(1.0 - (0.1 * progress))
                    .opacity(1.0 - (progress * 0.8))
                    .blur(radius: progress * 10)
                    .modifier(BlobMaskModifier(progress: progress))
                
            case .custom(let transitionFactory):
                content
                    .transition(transitionFactory(progress > 0.5))
            }
        }
    }
    
    /// Actual bubble mask implementation
    struct BubbleExpandMask: View {
        let progress: CGFloat
        let origin: CGPoint
        let size: CGSize
        
        var body: some View {
            // Calculate the maximum radius needed to cover the screen
            let maxDistance = sqrt(pow(size.width, 2) + pow(size.height, 2))
            
            // Calculate the radius based on progress (inverse for showing/hiding)
            let radius = maxDistance * (1.0 - progress)
            
            // Default to center if no origin provided
            let center = origin == .zero ?
            CGPoint(x: size.width / 2, y: size.height / 2) : origin
            
            return Circle()
                .frame(width: radius * 2, height: radius * 2)
                .position(x: center.x, y: center.y)
                .blur(radius: 15)
        }
    }
}

// Custom blob mask modifier for moodMorph transition
struct BlobMaskModifier: ViewModifier {
    let progress: CGFloat
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .mask(
                Canvas { context, size in
                    // Draw blob shape that morphs with progress
                    let center = CGPoint(x: size.width/2, y: size.height/2)
                    let radius = min(size.width, size.height) * 0.5
                    
                    var path = Path()
                    let points = 8
                    
                    // Create a blob shape that morphs with progress
                    for i in 0..<points {
                        let angle = 2 * .pi / CGFloat(points) * CGFloat(i)
                        let pct = CGFloat(i) / CGFloat(points)
                        
                        // Add some randomness that changes with progress
                        let noiseFactor = 0.2 + (sin(progress * 10 + pct * 20) * 0.1)
                        let pointRadius = radius * (1.0 + noiseFactor)
                        
                        let x = center.x + cos(angle + phase) * pointRadius
                        let y = center.y + sin(angle + phase) * pointRadius
                        
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.closeSubpath()
                    
                    // Fill the path
                    context.fill(path, with: .color(.black))
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 2 * .pi
                }
            }
    }
}

// Extension for easier application
extension View {
    /// Apply a mood animation style
    func moodTransition(
        style: TransitionStyle,
        progress: CGFloat,
        origin: CGPoint,
        size: CGSize
    ) -> some View {
        modifier(MoodAnimations.TransitionModifier(
            style: style,
            progress: progress,
            originPoint: origin,
            screenSize: size
        ))
    }
    
    /// Apply just the bubble expand mask effect
    func bubbleExpandMask(progress: CGFloat, origin: CGPoint, size: CGSize) -> some View {
        mask(
            MoodAnimations.BubbleExpandMask(
                progress: progress,
                origin: origin,
                size: size
            )
        )
    }
}
