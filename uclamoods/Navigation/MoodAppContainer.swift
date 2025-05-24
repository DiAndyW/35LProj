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
                
                // Current screen with appropriate transitions
                Group {
                    switch router.currentScreen {
                    case .energySelection:
                        EnergySelectionView()
                            .moodTransition(
                                style: .bubbleExpand,
                                progress: router.transitionProgress,
                                origin: router.transitionOrigin,
                                size: geometry.size
                            )
                            .scaleEffect(1.0 + (0.2 * router.transitionProgress))
                            .opacity(1.0 - (router.transitionProgress * 0.8))
                        
                    case .emotionSelection(let energyLevel):
                        EmotionSelectionView(energyLevel: energyLevel)
                            .moodTransition(
                                style: .bubbleExpand,
                                progress: router.transitionProgress,
                                origin: router.transitionOrigin,
                                size: geometry.size
                            )
                            .scaleEffect(1.0 + (0.2 * router.transitionProgress))
                            .opacity(1.0 - (router.transitionProgress * 1.0))
                        
                    case .completeCheckIn(let emotion):
                        CompleteCheckInView(emotion: emotion)
                            .moodTransition(
                                style: .bubbleExpand,
                                progress: router.transitionProgress,
                                origin: router.transitionOrigin,
                                size: geometry.size
                            )
                            .scaleEffect(1.0 + (0.2 * router.transitionProgress))
                            .opacity(1.0 - (router.transitionProgress * 0.8))
                    case .home:
                        HomeView()
                    
                    case .settings:
                        SettingsView()
                    
                    case .friends:
                        FriendsView()
                    
                    case .stats:
                        StatsView()
                        
                    case .signIn:
                        SignInView()
                        
                    case .signUp:
                        SignUpView()
                    
                    case .completeProfile:
                        CompleteProfileView()
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

#Preview {
    MoodAppContainer()
}
