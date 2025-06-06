//
//  EmotionSearchView.swift
//  uclamoods
//
//  Created by David Sun on 6/5/25.
//
import SwiftUI

struct EmotionSearchView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    
    private let allEmotions: [Emotion] =
    EmotionDataProvider.lowEnergyEmotions +
    EmotionDataProvider.mediumEnergyEmotions +
    EmotionDataProvider.highEnergyEmotions
    
    // Computed property to filter emotions based on search text
    private var filteredEmotions: [Emotion] {
        if searchText.isEmpty {
            return allEmotions
        } else {
            return allEmotions.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if filteredEmotions.isEmpty {
                            Text("No emotions found for \"\(searchText)\"")
                                .foregroundColor(.gray)
                                .padding(.top, 50)
                        } else {
                            ForEach(filteredEmotions) { emotion in
                                emotionRow(for: emotion)
                            }
                        }
                    }
                }
                .navigationTitle("Search Emotions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.pink)
                    }
                }
                .searchable(text: $searchText, prompt: "e.g., Happy, Anxious...")
            }
            .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func emotionRow(for emotion: Emotion) -> some View {
        Button(action: {
            guard let energyLevel = EmotionDataProvider.getEnergyLevel(for: emotion) else {
                print("Error: Could not determine energy level for \(emotion.name)")
                return
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                router.navigateToEmotionSelection(energyLevel: energyLevel, initialEmotionID: emotion.id)
            }
        }) {
            HStack(spacing: 16) {
                Circle()
                    .fill(emotion.color)
                    .frame(width: 12, height: 12)
                
                Text(emotion.name)
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        Divider().background(Color.white.opacity(0.2))
    }
}
