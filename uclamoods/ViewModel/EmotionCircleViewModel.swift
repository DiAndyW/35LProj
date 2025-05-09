//
//  EmotionCircleViewModel.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

class EmotionCircleViewModel: ObservableObject {
    @Published var pressScale: CGFloat = 1.0
    
    func triggerPressAnimation() {
        // Animate a quick press effect
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            pressScale = 0.95
        }
        
        // Reset scale after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                self.pressScale = 1.0
            }
        }
    }
}
