import SwiftUI

struct EnergySelectionView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var isShowingSearchView = false
    
    let blobSize = 200.0
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        router.navigateBackInMoodFlow(from: CGPoint(x: 50, y: 100))
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingSearchView = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.bottom, 20)
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
                FloatingBlobButton(
                    text: "High",
                    size: 220,
                    startColor: Color("Rage"),
                    endColor: Color("Euphoric"),
                    morphSpeed: 1.25, floatSpeed: 1.0, colorShiftSpeed: 3.0,
                    colorPool: [Color("Rage"), Color("Euphoric")],
                    action: {
                        router.navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel.high)
                    }
                )
                .frame(width: blobSize, height: blobSize)
                
                // Medium Energy Blob Button
                FloatingBlobButton(
                    text: "Medium",
                    size: 220,
                    startColor: Color("Disgusted"),
                    endColor: Color("Blissful"),
                    morphSpeed: 1.0, floatSpeed: 0.75, colorShiftSpeed: 2.0,
                    colorPool: [Color("Disgusted"), Color("Blissful")],
                    action: {
                        router.navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel.medium)
                    }
                )
                .frame(width: blobSize, height: blobSize)
                
                // Low Energy Blob Button
                FloatingBlobButton(
                    text: "Low",
                    size: 220,
                    startColor: Color("Miserable"),
                    endColor: Color("Blessed"),
                    morphSpeed: 0.75, floatSpeed: 0.5, colorShiftSpeed: 1.0,
                    colorPool: [Color("Miserable"), Color("Blessed")],
                    action: {
                        router.navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel.low)
                    }
                )
                .frame(width: blobSize, height: blobSize)
            }
        }
        .sheet(isPresented: $isShowingSearchView) {
            EmotionSearchView()
                .environmentObject(router)
        }
    }
}
