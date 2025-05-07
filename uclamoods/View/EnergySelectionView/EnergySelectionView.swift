//
//  EnergySelectionView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/6/25.
//

import SwiftUI

struct EnergySelectionView: View {
    @State private var navigateToEmotions = false
    @State private var selectedEnergy: String = ""
    // Sample energy levels with their colors
    let energyOptions: [(word: String, color: Color)] = [
        ("High", .red),
        ("Medium", .orange),
        ("Low", .blue)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Tap the color that best describes your energy level right now")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .font(.custom("Georgia", size: 24))
                
                
                ForEach(energyOptions, id: \.word) { option in
                    EnergyCircleView(
                        word: option.word,
                        color: option.color,
                        action: {
                            selectedEnergy = option.word
                            
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred()
                            
                            // Navigate to EmotionSelectionView
                            navigateToEmotions = true
                        }
                    )
                    .frame(width: 150, height: 150)
                }
            }
            .padding()
            .navigationDestination(isPresented: $navigateToEmotions) {
                // Determine which emotions to show based on selected energy
                let emotions = getEmotionsForEnergy(selectedEnergy)
                
                // Navigate to EmotionSelectionView
                EmotionSelectionView(emotions: emotions)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    private func getEmotionsForEnergy(_ energy: String) -> [Emotion] {
        switch energy {
        case "High":
            return EmotionDataProvider.highEnergyEmotions
            //        case "Medium":
            //            return EmotionDataProvider.mediumEnergyEmotions
            //        case "Low":
            //            return EmotionDataProvider.lowEnergyEmotions
        default:
            return EmotionDataProvider.highEnergyEmotions
        }
    }
}

struct EnergySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        EnergySelectionView()
            .preferredColorScheme(.dark)
    }
}
