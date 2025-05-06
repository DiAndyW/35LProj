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
    // Helper function to interpolate between two colors based on pleasantness
    private static func interpolateColor(pleasantness: Double, startColor: (r: Double, g: Double, b: Double), endColor: (r: Double, g: Double, b: Double)) -> Color {
        let t = pleasantness // pleasantness is already 0.0 to 1.0
        let r = startColor.r + (endColor.r - startColor.r) * t
        let g = startColor.g + (endColor.g - startColor.g) * t
        let b = startColor.b + (endColor.b - startColor.b) * t
        return Color(red: r, green: g, blue: b)
    }
    
    // Define start and end colors (converted from hex to RGB fractions)
    private static let rageColor = (r: 208.0/255.0, g: 0.0/255.0, b: 0.0/255.0) // D00000
    private static let euphoricColor = (r: 255.0/255.0, g: 186.0/255.0, b: 8.0/255.0) // FFBA08
    
    // Provides a list of emotions with a color gradient from D00000 (negative) to FFBA08 (positive)
    static let highEnergyEmotions: [Emotion] = [
        // Shortened descriptions for each emotion
        // Further shortened descriptions for each emotion
        Emotion(name: "Enraged",
                color: interpolateColor(pleasantness: 0.05, startColor: rageColor, endColor: euphoricColor),
                description: "Consumed by fiery anger, a raging storm of fury boiling over, barely contained, ready to explode.",
                pleasantness: 0.05, intensity: 0.9, control: 0.2, clarity: 0.9),

        Emotion(name: "Terrified",
                color: interpolateColor(pleasantness: 0.1, startColor: rageColor, endColor: euphoricColor),
                description: "Paralyzed by fear, heart pounding as danger looms, every nerve screaming in frozen panic.",
                pleasantness: 0.1, intensity: 0.95, control: 0.1, clarity: 0.8),

        Emotion(name: "Panicked",
                color: interpolateColor(pleasantness: 0.15, startColor: rageColor, endColor: euphoricColor),
                description: "Frantic, your heart races, mind spiraling in chaos, struggling for grip amid overwhelming turmoil.",
                pleasantness: 0.15, intensity: 0.9, control: 0.2, clarity: 0.7),

        Emotion(name: "Frustrated",
                color: interpolateColor(pleasantness: 0.2, startColor: rageColor, endColor: euphoricColor),
                description: "Irritated, you're stuck against obstacles, tension rising as efforts feel blocked by resistance.",
                pleasantness: 0.2, intensity: 0.7, control: 0.4, clarity: 0.8),

        Emotion(name: "Anxious",
                color: interpolateColor(pleasantness: 0.25, startColor: rageColor, endColor: euphoricColor),
                description: "Worry floods your mind with uneasy thoughts, nerves frayed, anticipating threats that feel real.",
                pleasantness: 0.25, intensity: 0.8, control: 0.3, clarity: 0.7),

        Emotion(name: "Overwhelmed",
                color: interpolateColor(pleasantness: 0.3, startColor: rageColor, endColor: euphoricColor),
                description: "Swamped by emotions and demands, struggling to stay afloat, gasping for clarity amid strain.",
                pleasantness: 0.3, intensity: 0.85, control: 0.3, clarity: 0.6),

        Emotion(name: "Shocked",
                color: interpolateColor(pleasantness: 0.4, startColor: rageColor, endColor: euphoricColor),
                description: "Jolted by alarm, senses spiking as the unexpected hits, leaving you reeling with awareness.",
                pleasantness: 0.4, intensity: 0.9, control: 0.3, clarity: 0.9),

        Emotion(name: "Surprised",
                color: interpolateColor(pleasantness: 0.5, startColor: rageColor, endColor: euphoricColor),
                description: "Startled by a twist, curiosity sparks, mind buzzing as the unexpected stirs your attention.",
                pleasantness: 0.5, intensity: 0.75, control: 0.5, clarity: 0.8),

        Emotion(name: "Excited",
                color: interpolateColor(pleasantness: 0.6, startColor: rageColor, endColor: euphoricColor),
                description: "Surging enthusiasm, eager to leap forward, heart racing with anticipation for possibilities.",
                pleasantness: 0.6, intensity: 0.85, control: 0.6, clarity: 0.8),

        Emotion(name: "Motivated",
                color: interpolateColor(pleasantness: 0.65, startColor: rageColor, endColor: euphoricColor),
                description: "Driven by purpose, energized and focused, ready to tackle challenges with determination.",
                pleasantness: 0.65, intensity: 0.8, control: 0.7, clarity: 0.9),

        Emotion(name: "Energized",
                color: interpolateColor(pleasantness: 0.7, startColor: rageColor, endColor: euphoricColor),
                description: "Brimming with energy, invigorated and ready to conquer challenges with unstoppable momentum.",
                pleasantness: 0.7, intensity: 0.9, control: 0.7, clarity: 0.7),

        Emotion(name: "Hyper",
                color: interpolateColor(pleasantness: 0.75, startColor: rageColor, endColor: euphoricColor),
                description: "Buzzing with wild energy, too wired to focus, bouncing with excitement that might overflow.",
                pleasantness: 0.75, intensity: 0.95, control: 0.4, clarity: 0.6),

        Emotion(name: "Thrilled",
                color: interpolateColor(pleasantness: 0.8, startColor: rageColor, endColor: euphoricColor),
                description: "Rushing with joy, swept up in exciting moments, heart soaring with achievement's thrill.",
                pleasantness: 0.8, intensity: 0.9, control: 0.6, clarity: 0.8),

        Emotion(name: "Inspired",
                color: interpolateColor(pleasantness: 0.85, startColor: rageColor, endColor: euphoricColor),
                description: "Uplifted by vision, motivated to create, driven by deep purpose and creative energy.",
                pleasantness: 0.85, intensity: 0.8, control: 0.6, clarity: 0.9),

        Emotion(name: "Exhilarated",
                color: interpolateColor(pleasantness: 0.9, startColor: rageColor, endColor: euphoricColor),
                description: "Electrified with joy, soaring with energy, every moment alive with vibrant excitement.",
                pleasantness: 0.9, intensity: 0.95, control: 0.7, clarity: 0.8),

        Emotion(name: "Euphoric",
                color: interpolateColor(pleasantness: 0.95, startColor: rageColor, endColor: euphoricColor),
                description: "Floating in happiness, filled with pure bliss, every sense alive with elation and joy.",
                pleasantness: 0.95, intensity: 1.0, control: 0.8, clarity: 0.9)
    ]
    
    // Default emotion accessor
    static var defaultEmotion: Emotion {
        highEnergyEmotions.first { $0.name == "Excited" } ?? highEnergyEmotions[8]
    }
}
