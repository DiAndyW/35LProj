//
//  EmotionCircleView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/5/25.
import SwiftUI

struct EmotionCircleView: View {
    let emotion: Emotion
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(emotion.color)
                .shadow(color: emotion.color.opacity(0.6), radius: isSelected ? 10 : 3, x: 0, y: isSelected ? 5 : 2)
                .scaleEffect(isSelected ? 1.0 : 0.8)
            
            Text(emotion.name)
                //.font(.system(size: 20, weight: .bold))
                .font(.custom("Georgia", size: 24))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(4)
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .opacity(isSelected ? 1.0 : 0.7)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
    }
}

struct EmotionCircleView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionCircleView(
            emotion: EmotionDataProvider.highEnergyEmotions[0],
            isSelected: true
        )
        .frame(width: 150, height: 150)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
