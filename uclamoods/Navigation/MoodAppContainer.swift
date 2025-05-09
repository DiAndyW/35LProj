//
//  MoodAppContainer.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

struct MoodAppContainer: View {
    @StateObject private var router = MoodAppRouter()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background stays consistent across transitions
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Current screen with bubble expand transition
                Group {
                    switch router.currentScreen {
                    case .energySelection:
                        EnergySelectionView()
                            .mask(
                                BubbleExpandMask(
                                    progress: router.transitionProgress,
                                    origin: router.transitionOrigin,
                                    size: geometry.size
                                )
                            )
                            .opacity(1.0 - (router.transitionProgress * 0.8))
                            .scaleEffect(1.0 - (0.1 * router.transitionProgress))
                            
                        
                    case .emotionSelection(let energyLevel):
                        EmotionSelectionView(energyLevel: energyLevel)
                            .mask(
                                BubbleExpandMask(
                                    progress: router.transitionProgress,
                                    origin: router.transitionOrigin,
                                    size: geometry.size
                                )
                            )
                            .opacity(1.0 - (router.transitionProgress * 0.8))
                            .scaleEffect(1.0 - (0.1 * router.transitionProgress))       
                    }
                }
            }
            .environmentObject(router)
            .onAppear {
                // Pass the screen size to the router when the view appears
                router.setScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                // Update if size changes (e.g., rotation)
                router.setScreenSize(newSize)
            }
        }
    }
    private func getEmotionsList(for energyLevel: String?) -> [Emotion] {
        guard let level = energyLevel else {
            return EmotionDataProvider.highEnergyEmotions // Fallback
        }
        switch level.lowercased() {
        case "high":
            return EmotionDataProvider.highEnergyEmotions
        case "medium":
            return EmotionDataProvider.mediumEnergyEmotions
        case "low":
            return EmotionDataProvider.lowEnergyEmotions
        default:
            return EmotionDataProvider.highEnergyEmotions
        }
    }
}

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
            .blur(radius: 2)
    }
}
