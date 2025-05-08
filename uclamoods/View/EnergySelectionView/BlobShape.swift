//
//  BlobShape.swift
//  uclamoods
//
//  Created by Yang Gao on 5/7/25.
//


import SwiftUI

struct BlobShape: Shape {
    var controlPoints: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let segments = controlPoints.count
            
            path.move(to: point(for: 0, radius: radius, center: center))
            
            for i in 0..<segments {
                let nextIndex = (i + 1) % segments
                let current = point(for: i, radius: radius, center: center)
                let next = point(for: nextIndex, radius: radius, center: center)
                let control1 = controlPoint(for: i, radius: radius, center: center)
                let control2 = controlPoint(for: nextIndex, radius: radius, center: center, isSecond: true)
                path.addCurve(to: next, control1: control1, control2: control2)
            }
            path.closeSubpath()
        }
    }
    
    private func point(for index: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = CGFloat(index) * (2 * .pi / CGFloat(controlPoints.count))
        let pointRadius = radius * (0.8 + controlPoints[index].x * 0.2)
        return CGPoint(
            x: center.x + pointRadius * cos(angle),
            y: center.y + pointRadius * sin(angle)
        )
    }
    
    private func controlPoint(for index: Int, radius: CGFloat, center: CGPoint, isSecond: Bool = false) -> CGPoint {
        let angle = CGFloat(index) * (2 * .pi / CGFloat(controlPoints.count))
        let offset = controlPoints[index].y * radius * 0.3
        let controlAngle = angle + (isSecond ? -0.2 : 0.2)
        return CGPoint(
            x: center.x + (radius + offset) * cos(controlAngle),
            y: center.y + (radius + offset) * sin(controlAngle)
        )
    }
    
    // Define animatableData for smooth animation
    var animatableData: [AnimatablePair<CGFloat, CGFloat>] {
        get {
            controlPoints.map { AnimatablePair($0.x, $0.y) }
        }
        set {
            controlPoints = newValue.map { CGPoint(x: $0.first, y: $0.second) }
        }
    }
}

struct FloatingBlobView: View {
    @State private var controlPoints: [CGPoint] = (0..<8).map { _ in
        CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
    }
    @State private var offset = CGSize.zero
    @State private var hueRotation = Angle.degrees(0)
    
    var body: some View {
        GeometryReader { geometry in
            BlobShape(controlPoints: controlPoints)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hue: 0.6, saturation: 0.8, brightness: 0.9),
                            Color(hue: 0.8, saturation: 0.8, brightness: 0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 10)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .offset(offset)
                .hueRotation(hueRotation)
                .onAppear {
                    startAnimations(in: geometry.size)
                }
        }
        .frame(width: 200, height: 200)
    }
    
    private func startAnimations(in size: CGSize) {
        // Animate blob shape
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            controlPoints = (0..<8).map { _ in
                CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
            }
        }
        
        // Animate floating motion
        let maxX = size.width - 200 // Adjust based on blob size
        let maxY = size.height - 200
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            offset = CGSize(
                width: CGFloat.random(in: -maxX/2...maxX/2),
                height: CGFloat.random(in: -maxY/2...maxY/2)
            )
        }
        
        // Animate color shift
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
            hueRotation = Angle.degrees(360)
        }
    }
}

struct FloatingBlobView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingBlobView()
            //.background(Color.black.opacity(0.1))
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
    }
}
