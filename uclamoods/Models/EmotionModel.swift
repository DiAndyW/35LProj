import SwiftUI

// MARK: - Emotion Model
struct Emotion: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let description: String
    let pleasantness: Double    // Scale from 0.0 (negative) to 1.0 (positive)
    let intensity: Double  // Scale from 0.0 (mild) to 1.0 (strong)
    let control: Double    // Scale from 0.0 (out of control) to 1.0 (in control)
    let clarity: Double    // Scale from 0.0 (conflicted) to 1.0 (genuine)
}

// MARK: - Emotion Data Provider
struct EmotionDataProvider {
    // Provides a list of emotions with a color gradient from red (negative) to blue (positive)
    static let highEnergyEmotions: [Emotion] = [
        Emotion(name: "Enraged",
                color: .red,
                description: "You feel consumed by intense anger and fury, as if your emotions are boiling over uncontrollably.",
                pleasantness: 0.1,     // Highly negative
                intensity: 0.9,   // Very strong
                control: 0.2,     // Feels out of control
                clarity: 0.9),    // Genuine and clear

        Emotion(name: "Frustrated",
                color: Color(red: 0.95, green: 0.3, blue: 0.2),
                description: "You feel irritated and impatient, struggling against obstacles that block your path forward.",
                pleasantness: 0.2,     // Negative
                intensity: 0.7,   // Moderately strong
                control: 0.4,     // Somewhat out of control
                clarity: 0.8),    // Fairly genuine

        Emotion(name: "Anxious",
                color: Color(red: 0.9, green: 0.4, blue: 0.3),
                description: "You feel overwhelmed by worry and nervous tension, your mind racing with uneasy thoughts.",
                pleasantness: 0.25,    // Negative
                intensity: 0.8,   // Strong
                control: 0.3,     // Mostly out of control
                clarity: 0.7),    // Somewhat genuine

        Emotion(name: "Shocked",
                color: Color(red: 0.85, green: 0.5, blue: 0.4),
                description: "You feel jolted by sudden surprise or alarm, your senses heightened by the unexpected.",
                pleasantness: 0.4,     // Slightly negative to neutral
                intensity: 0.9,   // Very strong
                control: 0.3,     // Mostly out of control
                clarity: 0.9),    // Genuine and clear

        Emotion(name: "Excited",
                color: Color(red: 0.7, green: 0.6, blue: 0.5),
                description: "You feel a surge of enthusiasm and eager anticipation, ready to dive into what lies ahead.",
                pleasantness: 0.7,     // Positive
                intensity: 0.85,  // Strong
                control: 0.6,     // Moderately in control
                clarity: 0.8),    // Fairly genuine

        Emotion(name: "Energized",
                color: Color(red: 0.5, green: 0.6, blue: 0.7),
                description: "You feel invigorated with vibrant energy, brimming with motivation to take on challenges.",
                pleasantness: 0.8,     // Positive
                intensity: 0.9,   // Very strong
                control: 0.7,     // Mostly in control
                clarity: 0.7),    // Somewhat genuine

        Emotion(name: "Inspired",
                color: Color(red: 0.4, green: 0.5, blue: 0.8),
                description: "You feel uplifted and motivated, sparked by a vision to create or achieve something meaningful.",
                pleasantness: 0.85,    // Highly positive
                intensity: 0.8,   // Strong
                control: 0.6,     // Moderately in control
                clarity: 0.9),    // Genuine and clear

        Emotion(name: "Exhilarated",
                color: Color(red: 0.3, green: 0.4, blue: 0.9),
                description: "You feel electrified with intense joy and liveliness, as if you’re soaring with boundless energy.",
                pleasantness: 0.9,     // Highly positive
                intensity: 0.95,  // Extremely strong
                control: 0.7,     // Mostly in control
                clarity: 0.8),    // Fairly genuine

        Emotion(name: "Euphoric",
                color: .blue,
                description: "You feel overwhelmed with profound happiness and elation, as if floating in a state of pure bliss.",
                pleasantness: 0.95,    // Extremely positive
                intensity: 1.0,   // Maximum strength
                control: 0.8,     // Mostly in control
                clarity: 0.9)     // Genuine and clear
    ]
    
    // Default emotion accessor
    static var defaultEmotion: Emotion {
        highEnergyEmotions.first { $0.name == "Excited" } ?? highEnergyEmotions[4]
    }
}
