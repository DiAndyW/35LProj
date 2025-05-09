//
//  AdvancedTransitionModifier.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

struct AdvancedTransitionModifier: ViewModifier {
    let style: TransitionStyle
    let progress: CGFloat // 0 = fully visible, 1 = fully invisible
    let originPoint: CGPoint
    let screenSize: CGSize
    
    func body(content: Content) -> some View {
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
            // Circular reveal/hide effect
            GeometryReader { proxy in
                content
                    .scaleEffect(1.0 - (0.05 * progress))
                    .mask(
                        Circle()
                            .scale(progress < 0.01 ? 1.0 : (1.0 - progress) * 2.0)
                            .position(
                                x: originPoint.x == 0 ? proxy.size.width / 2 : originPoint.x,
                                y: originPoint.y == 0 ? proxy.size.height / 2 : originPoint.y
                            )
                    )
            }
            
        case .revealMask:
            // Gradient reveal
            content
                .opacity(1.0 - (progress * 0.5))
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
                .scaleEffect(1.0 - (0.1 * progress), anchor: .top)
                
        case .moodMorph:
            // Wavy, morphing transition for mood app
            content
                .scaleEffect(1.0 - (0.1 * progress))
                .opacity(1.0 - (progress * 0.8))
                .modifier(BlobMaskModifier(progress: progress))
                .blur(radius: progress * 10)
                
        case .custom(let transitionFactory):
            content
                .transition(transitionFactory(progress > 0.5))
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
