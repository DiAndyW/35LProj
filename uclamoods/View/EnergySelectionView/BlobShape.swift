import SwiftUI

// Define a custom type for animatable control points
struct AnimatablePoints: VectorArithmetic {
    var points: [CGPoint]

    // Required by VectorArithmetic
    var magnitudeSquared: Double {
        // A simple sum of squares of all coordinates.
        // This specific calculation isn't critical for the animation to work,
        // as long as it returns a consistent Double.
        points.reduce(0.0) { sum, point in
            sum + Double(point.x * point.x + point.y * point.y)
        }
    }

    mutating func scale(by rhs: Double) {
        points = points.map { point in
            CGPoint(x: point.x * CGFloat(rhs), y: point.y * CGFloat(rhs))
        }
    }

    // Required by VectorArithmetic.
    // Assumes a fixed number of control points (e.g., 8 as used in your views).
    // Adjust count if your number of control points varies and requires a different zero state.
    static var zero: AnimatablePoints {
        // Your current implementation uses 8 control points.
        return AnimatablePoints(points: Array(repeating: CGPoint.zero, count: 8))
    }

    // Required by VectorArithmetic
    static func + (lhs: AnimatablePoints, rhs: AnimatablePoints) -> AnimatablePoints {
        // Ensure point counts match, which SwiftUI should handle for animations
        // of the same property.
        guard lhs.points.count == rhs.points.count else {
            // Fallback or error for mismatched counts, though ideally this won't be hit
            // during standard property animation.
            return lhs
        }
        var resultPoints: [CGPoint] = []
        for i in 0..<lhs.points.count {
            resultPoints.append(CGPoint(
                x: lhs.points[i].x + rhs.points[i].x,
                y: lhs.points[i].y + rhs.points[i].y
            ))
        }
        return AnimatablePoints(points: resultPoints)
    }

    // Required by VectorArithmetic
    static func - (lhs: AnimatablePoints, rhs: AnimatablePoints) -> AnimatablePoints {
        guard lhs.points.count == rhs.points.count else {
            return lhs
        }
        var resultPoints: [CGPoint] = []
        for i in 0..<lhs.points.count {
            resultPoints.append(CGPoint(
                x: lhs.points[i].x - rhs.points[i].x,
                y: lhs.points[i].y - rhs.points[i].y
            ))
        }
        return AnimatablePoints(points: resultPoints)
    }

    // Initializer
    init(points: [CGPoint]) {
        self.points = points
    }
}

struct BlobShape: Shape {
    var controlPoints: [CGPoint] // This remains your source of truth

    // Modify animatableData to use the new AnimatablePoints struct
    var animatableData: AnimatablePoints {
        get { AnimatablePoints(points: controlPoints) }
        set { self.controlPoints = newValue.points }
    }
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let segments = controlPoints.count
            
            // Ensure there are control points to draw, otherwise, path might be invalid
            guard segments > 0 else { return }
            
            path.move(to: point(for: 0, radius: radius, center: center))
            
            for i in 0..<segments {
                let nextIndex = (i + 1) % segments
                // let current = point(for: i, radius: radius, center: center) // current point already moved to or drawn to
                let next = point(for: nextIndex, radius: radius, center: center)
                let control1 = controlPoint(for: i, radius: radius, center: center)
                let control2 = controlPoint(for: nextIndex, radius: radius, center: center, isSecond: true)
                path.addCurve(to: next, control1: control1, control2: control2)
            }
            path.closeSubpath()
        }
    }
    
    private func point(for index: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        // Protect against index out of bounds if controlPoints is empty,
        // though animatableData.zero and path guard should help.
        guard !controlPoints.isEmpty else { return center }
        let angle = CGFloat(index) * (2 * .pi / CGFloat(controlPoints.count))
        // Ensure index is within bounds for controlPoints access
        let cpIndex = index % controlPoints.count
        let pointRadius = radius * (0.8 + controlPoints[cpIndex].x * 0.2)
        return CGPoint(
            x: center.x + pointRadius * cos(angle),
            y: center.y + pointRadius * sin(angle)
        )
    }
    
    private func controlPoint(for index: Int, radius: CGFloat, center: CGPoint, isSecond: Bool = false) -> CGPoint {
        guard !controlPoints.isEmpty else { return center }
        let angle = CGFloat(index) * (2 * .pi / CGFloat(controlPoints.count))
        // Ensure index is within bounds
        let cpIndex = index % controlPoints.count
        let offset = controlPoints[cpIndex].y * radius * 0.3
        let controlAngle = angle + (isSecond ? -0.2 : 0.2) // Small angle offset for bezier curve handles
        return CGPoint(
            x: center.x + (radius + offset) * cos(controlAngle),
            y: center.y + (radius + offset) * sin(controlAngle)
        )
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
