//
//  EmotionColorMap.swift
//  uclamoods
//
//  Created by Yang Gao on 6/3/25.
//


import SwiftUI

// MARK: - Emotion Color Map
struct EmotionColorMap {
    
    // Static color mapping for all emotions
    private static let colorMap: [String: Color] = {
        var map: [String: Color] = [:]
        
        let allEmotions = EmotionDataProvider.highEnergyEmotions + 
                         EmotionDataProvider.mediumEnergyEmotions + 
                         EmotionDataProvider.lowEnergyEmotions
        
        for emotion in allEmotions {
            map[emotion.name] = emotion.color
        }
        
        return map
    }()
    
    static func color(for emotionName: String) -> Color {
        return colorMap[emotionName] ?? Color.gray
    }
    
    static let staticColorMap: [String: Color] = [
        "Enraged": ColorData.calculateMoodColor(pleasantness: 0.05, intensity: 0.9) ?? .gray,
        "Terrified": ColorData.calculateMoodColor(pleasantness: 0.1, intensity: 0.95) ?? .gray,
        "Panicked": ColorData.calculateMoodColor(pleasantness: 0.15, intensity: 0.9) ?? .gray,
        "Stressed": ColorData.calculateMoodColor(pleasantness: 0.18, intensity: 0.85) ?? .gray,
        "Frustrated": ColorData.calculateMoodColor(pleasantness: 0.2, intensity: 0.7) ?? .gray,
        "Anxious": ColorData.calculateMoodColor(pleasantness: 0.25, intensity: 0.8) ?? .gray,
        "Overwhelmed": ColorData.calculateMoodColor(pleasantness: 0.3, intensity: 0.85) ?? .gray,
        "Shocked": ColorData.calculateMoodColor(pleasantness: 0.4, intensity: 0.9) ?? .gray,
        "Surprised": ColorData.calculateMoodColor(pleasantness: 0.5, intensity: 0.75) ?? .gray,
        "Excited": ColorData.calculateMoodColor(pleasantness: 0.6, intensity: 0.85) ?? .gray,
        "Motivated": ColorData.calculateMoodColor(pleasantness: 0.65, intensity: 0.8) ?? .gray,
        "Energized": ColorData.calculateMoodColor(pleasantness: 0.7, intensity: 0.9) ?? .gray,
        "Hyper": ColorData.calculateMoodColor(pleasantness: 0.75, intensity: 0.95) ?? .gray,
        "Thrilled": ColorData.calculateMoodColor(pleasantness: 0.8, intensity: 0.9) ?? .gray,
        "Proud": ColorData.calculateMoodColor(pleasantness: 0.82, intensity: 0.85) ?? .gray,
        "Inspired": ColorData.calculateMoodColor(pleasantness: 0.85, intensity: 0.8) ?? .gray,
        "Exhilarated": ColorData.calculateMoodColor(pleasantness: 0.9, intensity: 0.95) ?? .gray,
        "Euphoric": ColorData.calculateMoodColor(pleasantness: 0.95, intensity: 1.0) ?? .gray,
        
        // Medium Energy Emotions
        "Disgusted": ColorData.calculateMoodColor(pleasantness: 0.1, intensity: 0.6) ?? .gray,
        "Envious": ColorData.calculateMoodColor(pleasantness: 0.2, intensity: 0.55) ?? .gray,
        "Guilty": ColorData.calculateMoodColor(pleasantness: 0.25, intensity: 0.5) ?? .gray,
        "Troubled": ColorData.calculateMoodColor(pleasantness: 0.3, intensity: 0.5) ?? .gray,
        "Nervous": ColorData.calculateMoodColor(pleasantness: 0.32, intensity: 0.6) ?? .gray,
        "Disappointed": ColorData.calculateMoodColor(pleasantness: 0.35, intensity: 0.5) ?? .gray,
        "Irritated": ColorData.calculateMoodColor(pleasantness: 0.4, intensity: 0.55) ?? .gray,
        "Calm": ColorData.calculateMoodColor(pleasantness: 0.5, intensity: 0.4) ?? .gray,
        "Content": ColorData.calculateMoodColor(pleasantness: 0.55, intensity: 0.45) ?? .gray,
        "Challenged": ColorData.calculateMoodColor(pleasantness: 0.6, intensity: 0.6) ?? .gray,
        "Pleased": ColorData.calculateMoodColor(pleasantness: 0.65, intensity: 0.45) ?? .gray,
        "Hopeful": ColorData.calculateMoodColor(pleasantness: 0.7, intensity: 0.5) ?? .gray,
        "Accomplished": ColorData.calculateMoodColor(pleasantness: 0.75, intensity: 0.55) ?? .gray,
        "Affectionate": ColorData.calculateMoodColor(pleasantness: 0.78, intensity: 0.5) ?? .gray,
        "Grateful": ColorData.calculateMoodColor(pleasantness: 0.85, intensity: 0.5) ?? .gray,
        "Blissful": ColorData.calculateMoodColor(pleasantness: 0.9, intensity: 0.55) ?? .gray,
        
        // Low Energy Emotions
        "Miserable": ColorData.calculateMoodColor(pleasantness: 0.1, intensity: 0.3) ?? .gray,
        "Ashamed": ColorData.calculateMoodColor(pleasantness: 0.12, intensity: 0.4) ?? .gray,
        "Depressed": ColorData.calculateMoodColor(pleasantness: 0.15, intensity: 0.35) ?? .gray,
        "Lonely": ColorData.calculateMoodColor(pleasantness: 0.18, intensity: 0.38) ?? .gray,
        "Burned Out": ColorData.calculateMoodColor(pleasantness: 0.2, intensity: 0.3) ?? .gray,
        "Sad": ColorData.calculateMoodColor(pleasantness: 0.22, intensity: 0.4) ?? .gray,
        "Apathetic": ColorData.calculateMoodColor(pleasantness: 0.25, intensity: 0.25) ?? .gray,
        "Listless": ColorData.calculateMoodColor(pleasantness: 0.3, intensity: 0.3) ?? .gray,
        "Tired": ColorData.calculateMoodColor(pleasantness: 0.32, intensity: 0.28) ?? .gray,
        "Bored": ColorData.calculateMoodColor(pleasantness: 0.35, intensity: 0.35) ?? .gray,
        "Carefree": ColorData.calculateMoodColor(pleasantness: 0.5, intensity: 0.3) ?? .gray,
        "Relaxed": ColorData.calculateMoodColor(pleasantness: 0.55, intensity: 0.3) ?? .gray,
        "Secure": ColorData.calculateMoodColor(pleasantness: 0.65, intensity: 0.35) ?? .gray,
        "Satisfied": ColorData.calculateMoodColor(pleasantness: 0.75, intensity: 0.35) ?? .gray,
        "Serene": ColorData.calculateMoodColor(pleasantness: 0.85, intensity: 0.3) ?? .gray,
        "Blessed": ColorData.calculateMoodColor(pleasantness: 0.9, intensity: 0.35) ?? .gray
    ]
    
    static func getColor(for emotionName: String) -> Color {
        return staticColorMap[emotionName] ?? Color.gray
    }
}

