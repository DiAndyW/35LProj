//
//  EmotionRadarChartView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/5/25.
//

import SwiftUI

struct EmotionRadarChartView: View {
    let emotion: Emotion
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size * 0.4
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
                
                // Inner circles (25%, 50%, 75%)
                ForEach([0.25, 0.5, 0.75], id: \.self) { scale in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: radius * 2 * scale, height: radius * 2 * scale)
                }
                
                // Axis lines
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    path.move(to: CGPoint(x: center.x - radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                
                // Dimension labels
                Text("Pleasantness")
                    .font(.custom("Georgia", size: 12))
                    //.font(.caption)
                    .foregroundColor(.white)
                    .position(x: center.x, y: center.y - radius - 15)
                
                Text("Intensity")
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(.white)
                    .position(x: center.x + radius + 35, y: center.y)
                
                Text("Control")
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(.white)
                    .position(x: center.x, y: center.y + radius + 15)
                
                Text("Clarity")
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(.white)
                    .position(x: center.x - radius - 35, y: center.y)
                
                // Data polygon
                EmotionDataPolygon(
                    emotion: emotion,
                    center: center,
                    radius: radius
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
}

struct EmotionDataPolygon: View {
    let emotion: Emotion
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        Path { path in
            // Plot points for each dimension
            let pleasantnessPoint = CGPoint(
                x: center.x,
                y: center.y - radius * CGFloat(emotion.pleasantness)
            )
            
            let energyPoint = CGPoint(
                x: center.x + radius * CGFloat(emotion.intensity),
                y: center.y
            )
            
            let dominancePoint = CGPoint(
                x: center.x,
                y: center.y + radius * CGFloat(emotion.control)
            )
            
            let authenticityPoint = CGPoint(
                x: center.x - radius * CGFloat(emotion.clarity),
                y: center.y
            )
            
            path.move(to: pleasantnessPoint)
            path.addLine(to: energyPoint)
            path.addLine(to: dominancePoint)
            path.addLine(to: authenticityPoint)
            path.closeSubpath()
        }
        .fill(emotion.color.opacity(0.4))
        .overlay(
            Path { path in
                // Same points as above
                let pleasantnessPoint = CGPoint(
                    x: center.x,
                    y: center.y - radius * CGFloat(emotion.pleasantness)
                )
                
                let energyPoint = CGPoint(
                    x: center.x + radius * CGFloat(emotion.intensity),
                    y: center.y
                )
                
                let dominancePoint = CGPoint(
                    x: center.x,
                    y: center.y + radius * CGFloat(emotion.control)
                )
                
                let authenticityPoint = CGPoint(
                    x: center.x - radius * CGFloat(emotion.clarity),
                    y: center.y
                )
                
                path.move(to: pleasantnessPoint)
                path.addLine(to: energyPoint)
                path.addLine(to: dominancePoint)
                path.addLine(to: authenticityPoint)
                path.closeSubpath()
            }
            .stroke(emotion.color, lineWidth: 2)
        )
    }
}

struct EmotionRadarChartView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionRadarChartView(emotion: EmotionDataProvider.highEnergyEmotions[4])
            .frame(width: 300, height: 300)
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
