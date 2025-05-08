//
//  FloatingBlobView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

struct NewFloatingBlobView: View {
    @State private var controlPoints: [CGPoint] = (0..<8).map { _ in
        CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
    }
    @State private var offset = CGSize.zero
    @State private var hueRotation = Angle.degrees(0)
    
    let blobSize = 200.0
    
    var body: some View {
        VStack(spacing: 20) {
            GeometryReader { geometry in
                FloatingBlobButton(text: "High", startColor: Color("Rage"), endColor: Color("Euphoric"), morphSpeed: 3000000.0,floatSpeed: 3.0, colorShiftSpeed: 2.0, action: {})
            }
            .frame(width: blobSize, height: blobSize)
            GeometryReader { geometry in
                FloatingBlobButton(text: "Medium", startColor: Color("Disgusted"), endColor: Color("Blissful"), morphSpeed: 2.0,floatSpeed: 2.0, colorShiftSpeed: 1.0, action: {})
            }
            .frame(width: blobSize, height: blobSize)

            GeometryReader { geometry in
                FloatingBlobButton(text: "Low", startColor: Color("Miserable"), endColor: Color("Blessed"), morphSpeed: 2.0,floatSpeed: 2.0, colorShiftSpeed: 1.0, action: {})            }
            .frame(width: blobSize, height: blobSize)

        }
        
    }
    
    private func startAnimations(in size: CGSize) {
        // Animate blob shape
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            controlPoints = (0..<6).map { _ in
                CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
            }
        }
        
        // Animate floating motion
        let maxX = size.width - blobSize // Adjust based on blob size
        let maxY = size.height - blobSize
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
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

struct NewFloatingBlobView_Previews: PreviewProvider {
    static var previews: some View {
        NewFloatingBlobView()
            //.background(Color.black.opacity(0.1))
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
    }
}
