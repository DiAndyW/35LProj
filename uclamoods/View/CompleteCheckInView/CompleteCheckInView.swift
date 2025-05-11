//
//  CompleteCheckInView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//


import SwiftUI

struct CompleteCheckInView: View {
    @EnvironmentObject private var router: MoodAppRouter
    let emotion: Emotion
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background that matches the emotion color
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(emotion.color).opacity(0.8),
                        Color.black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Success animation/icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    // Completion message
                    Text("Check-in Complete")
                        .font(.custom("Georgia", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You're feeling \(emotion.name)")
                        .font(.custom("Georgia", size: 24))
                        .foregroundColor(.white)
                    
                    // Optional additional info
                    Text("Your mood has been recorded")
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 5)
                    
                    Spacer()
                    
                    // Done button
                    Button(action: {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred()
                        
                        // Navigate back
                        router.navigateBack()
                    }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: geometry.size.width * 0.6, height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
                .padding()
            }
        }
    }
}

#Preview {
    CompleteCheckInView(emotion: EmotionDataProvider.highEnergyEmotions[0])
}
