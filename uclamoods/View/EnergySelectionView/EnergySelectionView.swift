//
//  FloatingBlobView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

struct EnergySelectionView: View {
    @EnvironmentObject private var router: MoodAppRouter
    // State variables for custom animation and navigation
    @State private var animateElementsOut = false
    @State private var navigateToEmotionView = false
    @State private var selectedEnergyLevel: String? = nil // To know which emotion set to load
    
    let blobSize = 180.0
    let animationDuration = 0.5 // Duration for the zoom-out and fade-out animation
    
    var body: some View {
        // NavigationStack is needed for .navigationDestination.
        // Place it at the root of your navigation flow if it's not already there.
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.edgesIgnoringSafeArea(.all) // Assuming a dark background
                
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            // Handle back/dismiss action
                            router.navigateBack() // Assuming you have a goBack method in your router
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO:
                            //router.navigateToSearch()                                                // Handle search action
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Tap on the color that best describes your energy level")
                        .font(.custom("Georgia", size: 24))
                        .fontWeight(.regular)
                        .foregroundColor(.white)
                        .lineSpacing(1.5)
                        .padding(.top, -10)
                        .padding(.bottom, 20)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // High Energy Blob Button
                    // Replace 'FloatingBlobButtonPlaceholder' with your actual 'FloatingBlobButton'
                    // Ensure your 'FloatingBlobButton' takes 'blobSize' and 'action' parameters.
                    FloatingBlobButton(
                        text: "High",
                        startColor: Color("Rage"), // Ensure these colors are in your Assets.xcassets
                        endColor: Color("Euphoric"),
                        // Pass other parameters your FloatingBlobButton expects (morphSpeed, etc.)
                        morphSpeed: 3.0, floatSpeed: 3.0, colorShiftSpeed: 3.0,
                        action: {
                            router.navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel.high)
                        }
                    )
                    .frame(width: blobSize, height: blobSize) // As in your original layout
                    
                    // Medium Energy Blob Button
                    FloatingBlobButton(
                        text: "Medium",
                        startColor: Color("Disgusted"),
                        endColor: Color("Blissful"),
                        morphSpeed: 2.0, floatSpeed: 2.0, colorShiftSpeed: 2.0,
                        action: {
                            router.navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel.medium)
                        }
                    )
                    .frame(width: blobSize, height: blobSize)
                    
                    // Low Energy Blob Button
                    FloatingBlobButton(
                        text: "Low",
                        startColor: Color("Miserable"),
                        endColor: Color("Blessed"),
                        morphSpeed: 1.0, floatSpeed: 2.0, colorShiftSpeed: 1.0,
                        action: {
                            router.navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel.low)
                            
                        }
                    )
                    .frame(width: blobSize, height: blobSize)
                }
                // These modifiers will apply to the entire VStack of blobs
                .scaleEffect(animateElementsOut ? 0.5 : 1.0) // Zoom out effect
                .opacity(animateElementsOut ? 0.0 : 1.0)    // Fade out effect
            }
        }
    }
    
    // This function is called when a blob button is pressed
    private func triggerTransition(energyLevel: String) {
        self.selectedEnergyLevel = energyLevel // Store the selected energy level
        
        // Start the custom animation (zoom out, fade out)
        withAnimation(.easeOut(duration: animationDuration)) {
            animateElementsOut = true
        }
        
        // Delay the actual navigation until the animation is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            navigateToEmotionView = true
        }
    }
}

struct NewFloatingBlobView_Previews: PreviewProvider {
    static var previews: some View {
        EnergySelectionView()
        //.background(Color.black.opacity(0.1))
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
    }
}
