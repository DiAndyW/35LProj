import SwiftUI

// MARK: - Emotion Data Provider
struct EmotionDataProvider {
    enum EnergyLevel {
        case high, medium, low
    }
    
    // Static property to track the currently selected energy level
    static var selectedEnergyLevel: EnergyLevel = .high
    
    // Helper function to interpolate between two colors based on pleasantness
    private static func interpolateColor(pleasantness: Double, startColor: (r: Double, g: Double, b: Double), endColor: (r: Double, g: Double, b: Double)) -> Color {
        let t = pleasantness // pleasantness is already 0.0 to 1.0
        let r = startColor.r + (endColor.r - startColor.r) * t
        let g = startColor.g + (endColor.g - startColor.g) * t
        let b = startColor.b + (endColor.b - startColor.b) * t
        return Color(red: r, green: g, blue: b)
    }
    
    // Define start and end colors (converted from hex to RGB fractions)
    public static let rageColor = (r: 208.0/255.0, g: 0.0/255.0, b: 0.0/255.0) // D00000
    public static let euphoricColor = (r: 255.0/255.0, g: 215/255.0, b: 0.0/255.0) // FFBA08 (Original was FFBA08, using FFD700 for Gold as in example)
    
    public static let disgustedColor = (r: 111.0/255.0, g: 45.0/255.0, b: 189.0/255.0) // #6F2DBD
    public static let blissfulColor = (r: 185.0/255.0, g: 250.0/255.0, b: 248.0/255.0) // #B9FAF8
    
    public static let miserableColor = (r: 34.0/255.0, g: 87.0/255.0, b: 122.0/255.0) // #22577A
    public static let blessedColor = (r: 128.0/255.0, g: 237.0/255.0, b: 153.0/255.0) // #80ED99
    
    static var defaultEmotion: Emotion {
        switch selectedEnergyLevel {
        case .high:
            return highEnergyEmotions.first { $0.name == "Excited" } ?? highEnergyEmotions[10] // Adjusted index if needed
        case .medium:
            return mediumEnergyEmotions.first { $0.name == "Calm" } ?? mediumEnergyEmotions[7] // Adjusted index
        case .low:
            return lowEnergyEmotions.first { $0.name == "Relaxed" } ?? lowEnergyEmotions[9] // Adjusted index
        }
    }
    
    // Function to get emotions based on selected energy level
    static func getEmotionsForCurrentEnergyLevel() -> [Emotion] {
        switch selectedEnergyLevel {
        case .high:
            return highEnergyEmotions
        case .medium:
            return mediumEnergyEmotions
        case .low:
            return lowEnergyEmotions
        }
    }
    
    static let highEnergyEmotions: [Emotion] = [
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
        Emotion(name: "Stressed", // New
                color: interpolateColor(pleasantness: 0.18, startColor: rageColor, endColor: euphoricColor),
                description: "Under intense pressure, feeling overwhelmed by demands and finding it hard to cope, mind racing.",
                pleasantness: 0.18, intensity: 0.85, control: 0.25, clarity: 0.5),
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
        Emotion(name: "Proud", // New
                color: interpolateColor(pleasantness: 0.82, startColor: rageColor, endColor: euphoricColor),
                description: "Feeling a surge of elation and deep satisfaction from significant achievements or qualities.",
                pleasantness: 0.82, intensity: 0.85, control: 0.7, clarity: 0.85),
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
    
    static let mediumEnergyEmotions: [Emotion] = [
        Emotion(name: "Disgusted",
                color: interpolateColor(pleasantness: 0.1, startColor: disgustedColor, endColor: blissfulColor),
                description: "Repulsed by something vile, stomach churning with distaste, urging you to turn away.",
                pleasantness: 0.1, intensity: 0.6, control: 0.4, clarity: 0.7),
        Emotion(name: "Envious",
                color: interpolateColor(pleasantness: 0.2, startColor: disgustedColor, endColor: blissfulColor),
                description: "Stung by others' success, a bitter longing for what they have gnaws at your peace.",
                pleasantness: 0.2, intensity: 0.55, control: 0.5, clarity: 0.6),
        Emotion(name: "Guilty", // New
                color: interpolateColor(pleasantness: 0.25, startColor: disgustedColor, endColor: blissfulColor),
                description: "Feeling remorse and responsibility for a perceived wrongdoing, a weight on your conscience.",
                pleasantness: 0.25, intensity: 0.5, control: 0.4, clarity: 0.7),
        Emotion(name: "Troubled",
                color: interpolateColor(pleasantness: 0.3, startColor: disgustedColor, endColor: blissfulColor),
                description: "Uneasy, your mind wrestles with nagging worries, a quiet storm clouding your calm.",
                pleasantness: 0.3, intensity: 0.5, control: 0.5, clarity: 0.6),
        Emotion(name: "Stressed (Medium)", // New
                color: interpolateColor(pleasantness: 0.32, startColor: disgustedColor, endColor: blissfulColor),
                description: "Feeling persistent tension and pressure, managing ongoing demands that weigh on your mind.",
                pleasantness: 0.32, intensity: 0.6, control: 0.4, clarity: 0.6),
        Emotion(name: "Disappointed",
                color: interpolateColor(pleasantness: 0.35, startColor: disgustedColor, endColor: blissfulColor),
                description: "Let down by unmet hopes, a sinking feeling settles in, dimming your expectations.",
                pleasantness: 0.35, intensity: 0.5, control: 0.6, clarity: 0.7),
        Emotion(name: "Irritated",
                color: interpolateColor(pleasantness: 0.4, startColor: disgustedColor, endColor: blissfulColor),
                description: "Annoyed by small frustrations, a prickly edge sharpens your mood, testing patience.",
                pleasantness: 0.4, intensity: 0.55, control: 0.5, clarity: 0.8),
        Emotion(name: "Calm",
                color: interpolateColor(pleasantness: 0.5, startColor: disgustedColor, endColor: blissfulColor),
                description: "At ease, your mind is steady, a gentle balance holding you in quiet serenity.",
                pleasantness: 0.5, intensity: 0.4, control: 0.8, clarity: 0.9),
        Emotion(name: "Content",
                color: interpolateColor(pleasantness: 0.55, startColor: disgustedColor, endColor: blissfulColor),
                description: "Satisfied with the moment, a soft warmth of peace settles over you, untroubled.",
                pleasantness: 0.55, intensity: 0.45, control: 0.7, clarity: 0.8),
        Emotion(name: "Challenged",
                color: interpolateColor(pleasantness: 0.6, startColor: disgustedColor, endColor: blissfulColor),
                description: "Sparked by a test, your focus sharpens, eager to push your limits and grow.",
                pleasantness: 0.6, intensity: 0.6, control: 0.6, clarity: 0.8),
        Emotion(name: "Pleased", // New
                color: interpolateColor(pleasantness: 0.65, startColor: disgustedColor, endColor: blissfulColor),
                description: "Feeling happy and satisfied by an outcome or situation, a light and agreeable feeling.",
                pleasantness: 0.65, intensity: 0.45, control: 0.7, clarity: 0.8),
        Emotion(name: "Hopeful",
                color: interpolateColor(pleasantness: 0.7, startColor: disgustedColor, endColor: blissfulColor),
                description: "Lifted by possibility, your heart lightens with optimism for what lies ahead.",
                pleasantness: 0.7, intensity: 0.5, control: 0.7, clarity: 0.8),
        Emotion(name: "Accomplished",
                color: interpolateColor(pleasantness: 0.75, startColor: disgustedColor, endColor: blissfulColor),
                description: "Proud of your success, a glow of fulfillment warms you after reaching your goal.",
                pleasantness: 0.75, intensity: 0.55, control: 0.8, clarity: 0.9),
        Emotion(name: "Affectionate", // New
                color: interpolateColor(pleasantness: 0.78, startColor: disgustedColor, endColor: blissfulColor),
                description: "Feeling warmth, tenderness, and care towards someone or something, a gentle connection.",
                pleasantness: 0.78, intensity: 0.5, control: 0.7, clarity: 0.8),
        Emotion(name: "Grateful",
                color: interpolateColor(pleasantness: 0.85, startColor: disgustedColor, endColor: blissfulColor),
                description: "Heart warmed by appreciation, a deep sense of thankfulness grounds you in joy.",
                pleasantness: 0.85, intensity: 0.5, control: 0.8, clarity: 0.9),
        Emotion(name: "Blissful",
                color: interpolateColor(pleasantness: 0.9, startColor: disgustedColor, endColor: blissfulColor),
                description: "Wrapped in pure joy, a radiant lightness fills you, every moment glowing with ease.",
                pleasantness: 0.9, intensity: 0.55, control: 0.7, clarity: 0.8)
    ]
    
    static let lowEnergyEmotions: [Emotion] = [
        Emotion(name: "Miserable",
                color: interpolateColor(pleasantness: 0.1, startColor: miserableColor, endColor: blessedColor),
                description: "Sunk in deep sorrow, a heavy ache drains all light, leaving only despair.",
                pleasantness: 0.1, intensity: 0.3, control: 0.3, clarity: 0.5),
        Emotion(name: "Ashamed", // New
                color: interpolateColor(pleasantness: 0.12, startColor: miserableColor, endColor: blessedColor),
                description: "Feeling deep distress and humiliation from a perceived flaw or wrongdoing, wanting to hide.",
                pleasantness: 0.12, intensity: 0.4, control: 0.2, clarity: 0.6),
        Emotion(name: "Depressed",
                color: interpolateColor(pleasantness: 0.15, startColor: miserableColor, endColor: blessedColor),
                description: "Trapped in a fog of hopelessness, energy sapped, the world feels gray and distant.",
                pleasantness: 0.15, intensity: 0.35, control: 0.4, clarity: 0.4),
        Emotion(name: "Lonely", // New
                color: interpolateColor(pleasantness: 0.18, startColor: miserableColor, endColor: blessedColor),
                description: "Feeling isolated and disconnected from others, a yearning for companionship or understanding.",
                pleasantness: 0.18, intensity: 0.38, control: 0.3, clarity: 0.6),
        Emotion(name: "Burned Out",
                color: interpolateColor(pleasantness: 0.2, startColor: miserableColor, endColor: blessedColor),
                description: "Exhausted and empty, motivation gone, every task feels like an insurmountable weight.",
                pleasantness: 0.2, intensity: 0.3, control: 0.3, clarity: 0.5),
        Emotion(name: "Sad", // New
                color: interpolateColor(pleasantness: 0.22, startColor: miserableColor, endColor: blessedColor),
                description: "Feeling sorrow or unhappiness, often with a sense of loss or disappointment, a quiet ache.",
                pleasantness: 0.22, intensity: 0.4, control: 0.5, clarity: 0.7),
        Emotion(name: "Apathetic",
                color: interpolateColor(pleasantness: 0.25, startColor: miserableColor, endColor: blessedColor),
                description: "Numb to the world, nothing sparks interest, a dull void where feelings should be.",
                pleasantness: 0.25, intensity: 0.25, control: 0.5, clarity: 0.6),
        Emotion(name: "Listless",
                color: interpolateColor(pleasantness: 0.3, startColor: miserableColor, endColor: blessedColor),
                description: "Drifting without purpose, energy low, a quiet disinterest cloaks your thoughts.",
                pleasantness: 0.3, intensity: 0.3, control: 0.6, clarity: 0.6),
        Emotion(name: "Tired", // New
                color: interpolateColor(pleasantness: 0.32, startColor: miserableColor, endColor: blessedColor),
                description: "Lacking physical or mental energy, feeling weary and in need of rest, a sense of depletion.",
                pleasantness: 0.32, intensity: 0.28, control: 0.4, clarity: 0.8),
        Emotion(name: "Bored",
                color: interpolateColor(pleasantness: 0.35, startColor: miserableColor, endColor: blessedColor),
                description: "Restless in monotony, craving something new, time drags in a haze of disengagement.",
                pleasantness: 0.35, intensity: 0.35, control: 0.5, clarity: 0.7),
        Emotion(name: "Carefree",
                color: interpolateColor(pleasantness: 0.5, startColor: miserableColor, endColor: blessedColor),
                description: "Light and unburdened, worries slip away, leaving a gentle ease in the moment.",
                pleasantness: 0.5, intensity: 0.3, control: 0.7, clarity: 0.8),
        Emotion(name: "Relaxed",
                color: interpolateColor(pleasantness: 0.55, startColor: miserableColor, endColor: blessedColor),
                description: "At peace, tension melts away, a soft calm settles over body and mind.",
                pleasantness: 0.55, intensity: 0.3, control: 0.8, clarity: 0.8),
        Emotion(name: "Secure",
                color: interpolateColor(pleasantness: 0.65, startColor: miserableColor, endColor: blessedColor),
                description: "Safe and steady, a quiet confidence anchors you in a sense of stability.",
                pleasantness: 0.65, intensity: 0.35, control: 0.8, clarity: 0.9),
        Emotion(name: "Satisfied",
                color: interpolateColor(pleasantness: 0.75, startColor: miserableColor, endColor: blessedColor),
                description: "Content with what is, a warm fulfillment glows, no need for more than this moment.",
                pleasantness: 0.75, intensity: 0.35, control: 0.7, clarity: 0.8),
        Emotion(name: "Serene",
                color: interpolateColor(pleasantness: 0.85, startColor: miserableColor, endColor: blessedColor),
                description: "Deeply tranquil, a still lake of calm reflects clarity and quiet joy within.",
                pleasantness: 0.85, intensity: 0.3, control: 0.9, clarity: 0.9),
        Emotion(name: "Blessed",
                color: interpolateColor(pleasantness: 0.9, startColor: miserableColor, endColor: blessedColor),
                description: "Filled with gratitude, a gentle warmth of fortune embraces you, heart full.",
                pleasantness: 0.9, intensity: 0.35, control: 0.8, clarity: 0.9)
    ]
}

