import SwiftUI

// MARK: - Emotion Data Provider
struct EmotionDataProvider {
    enum EnergyLevel {
        case high, medium, low
    }
    
    // Static property to track the currently selected energy level
    static var selectedEnergyLevel: EnergyLevel = .high
    
    static var defaultEmotion: Emotion {
        let emotions = getEmotionsForCurrentEnergyLevel()
        let defaultName: String
        switch selectedEnergyLevel {
            case .high:
                defaultName = "Excited"
            case .medium:
                defaultName = "Calm"
            case .low:
                defaultName = "Relaxed"
        }
        // Provide a fallback if the named emotion isn't found or the list is empty
        return emotions.first { $0.name == defaultName } ?? emotions.first ?? fallbackEmotion
    }
    
    private static var fallbackEmotion: Emotion {
        Emotion(name: "Neutral",
                color: .gray, // Use a neutral color
                description: "A neutral emotional state.",
                pleasantness: 0.5, intensity: 0.5, control: 0.5, clarity: 0.5)
    }
    
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
    
    static func getEmotion(byName name: String) -> Emotion? {
        let allEmotions = highEnergyEmotions + mediumEnergyEmotions + lowEnergyEmotions
        return allEmotions.first { $0.name.lowercased() == name.lowercased() } ?? fallbackEmotion
    }
    
    static let highEnergyEmotions: [Emotion] = [
        Emotion(name: "Enraged",
                color: ColorData.calculateMoodColor(pleasantness: 0.05, intensity: 0.9) ?? .gray,
                description: "Consumed by fiery anger, a raging storm of fury boiling over, barely contained, ready to explode.",
                pleasantness: 0.05, intensity: 0.9, control: 0.2, clarity: 0.9),
        Emotion(name: "Terrified",
                color: ColorData.calculateMoodColor(pleasantness: 0.1, intensity: 0.95) ?? .gray,
                description: "Paralyzed by fear, heart pounding as danger looms, every nerve screaming in frozen panic.",
                pleasantness: 0.1, intensity: 0.95, control: 0.1, clarity: 0.8),
        Emotion(name: "Panicked",
                color: ColorData.calculateMoodColor(pleasantness: 0.15, intensity: 0.9) ?? .gray,
                description: "Frantic, your heart races, mind spiraling in chaos, struggling for grip amid overwhelming turmoil.",
                pleasantness: 0.15, intensity: 0.9, control: 0.2, clarity: 0.7),
        Emotion(name: "Stressed",
                color: ColorData.calculateMoodColor(pleasantness: 0.18, intensity: 0.85) ?? .gray,
                description: "Under intense pressure, feeling overwhelmed by demands and finding it hard to cope, mind racing.",
                pleasantness: 0.18, intensity: 0.85, control: 0.25, clarity: 0.5),
        Emotion(name: "Frustrated",
                color: ColorData.calculateMoodColor(pleasantness: 0.2, intensity: 0.7) ?? .gray,
                description: "Irritated, you're stuck against obstacles, tension rising as efforts feel blocked by resistance.",
                pleasantness: 0.2, intensity: 0.7, control: 0.4, clarity: 0.8),
        Emotion(name: "Anxious",
                color: ColorData.calculateMoodColor(pleasantness: 0.25, intensity: 0.8) ?? .gray,
                description: "Worry floods your mind with uneasy thoughts, nerves frayed, anticipating threats that feel real.",
                pleasantness: 0.25, intensity: 0.8, control: 0.3, clarity: 0.7),
        Emotion(name: "Overwhelmed",
                color: ColorData.calculateMoodColor(pleasantness: 0.3, intensity: 0.85) ?? .gray,
                description: "Swamped by emotions and demands, struggling to stay afloat, gasping for clarity amid strain.",
                pleasantness: 0.3, intensity: 0.85, control: 0.3, clarity: 0.6),
        Emotion(name: "Shocked",
                color: ColorData.calculateMoodColor(pleasantness: 0.4, intensity: 0.9) ?? .gray,
                description: "Jolted by alarm, senses spiking as the unexpected hits, leaving you reeling with awareness.",
                pleasantness: 0.4, intensity: 0.9, control: 0.3, clarity: 0.9),
        Emotion(name: "Surprised",
                color: ColorData.calculateMoodColor(pleasantness: 0.5, intensity: 0.75) ?? .gray,
                description: "Startled by a twist, curiosity sparks, mind buzzing as the unexpected stirs your attention.",
                pleasantness: 0.5, intensity: 0.75, control: 0.5, clarity: 0.8),
        Emotion(name: "Excited",
                color: ColorData.calculateMoodColor(pleasantness: 0.6, intensity: 0.85) ?? .gray,
                description: "Surging enthusiasm, eager to leap forward, heart racing with anticipation for possibilities.",
                pleasantness: 0.6, intensity: 0.85, control: 0.6, clarity: 0.8),
        Emotion(name: "Motivated",
                color: ColorData.calculateMoodColor(pleasantness: 0.65, intensity: 0.8) ?? .gray,
                description: "Driven by purpose, energized and focused, ready to tackle challenges with determination.",
                pleasantness: 0.65, intensity: 0.8, control: 0.7, clarity: 0.9),
        Emotion(name: "Energized",
                color: ColorData.calculateMoodColor(pleasantness: 0.7, intensity: 0.9) ?? .gray,
                description: "Brimming with energy, invigorated and ready to conquer challenges with unstoppable momentum.",
                pleasantness: 0.7, intensity: 0.9, control: 0.7, clarity: 0.7),
        Emotion(name: "Hyper",
                color: ColorData.calculateMoodColor(pleasantness: 0.75, intensity: 0.95) ?? .gray,
                description: "Buzzing with wild energy, too wired to focus, bouncing with excitement that might overflow.",
                pleasantness: 0.75, intensity: 0.95, control: 0.4, clarity: 0.6),
        Emotion(name: "Thrilled",
                color: ColorData.calculateMoodColor(pleasantness: 0.8, intensity: 0.9) ?? .gray,
                description: "Rushing with joy, swept up in exciting moments, heart soaring with achievement's thrill.",
                pleasantness: 0.8, intensity: 0.9, control: 0.6, clarity: 0.8),
        Emotion(name: "Proud",
                color: ColorData.calculateMoodColor(pleasantness: 0.82, intensity: 0.85) ?? .gray,
                description: "Feeling a surge of elation and deep satisfaction from significant achievements or qualities.",
                pleasantness: 0.82, intensity: 0.85, control: 0.7, clarity: 0.85),
        Emotion(name: "Inspired",
                color: ColorData.calculateMoodColor(pleasantness: 0.85, intensity: 0.8) ?? .gray,
                description: "Uplifted by vision, motivated to create, driven by deep purpose and creative energy.",
                pleasantness: 0.85, intensity: 0.8, control: 0.6, clarity: 0.9),
        Emotion(name: "Exhilarated",
                color: ColorData.calculateMoodColor(pleasantness: 0.9, intensity: 0.95) ?? .gray,
                description: "Electrified with joy, soaring with energy, every moment alive with vibrant excitement.",
                pleasantness: 0.9, intensity: 0.95, control: 0.7, clarity: 0.8),
        Emotion(name: "Euphoric",
                color: ColorData.calculateMoodColor(pleasantness: 0.95, intensity: 1.0) ?? .gray,
                description: "Floating in happiness, filled with pure bliss, every sense alive with elation and joy.",
                pleasantness: 0.95, intensity: 1.0, control: 0.8, clarity: 0.9)
    ]
    
    static let mediumEnergyEmotions: [Emotion] = [
        Emotion(name: "Disgusted",
                color: ColorData.calculateMoodColor(pleasantness: 0.1, intensity: 0.6) ?? .gray,
                description: "Repulsed by something vile, stomach churning with distaste, urging you to turn away.",
                pleasantness: 0.1, intensity: 0.6, control: 0.4, clarity: 0.7),
        Emotion(name: "Envious",
                color: ColorData.calculateMoodColor(pleasantness: 0.2, intensity: 0.55) ?? .gray,
                description: "Stung by others' success, a bitter longing for what they have gnaws at your peace.",
                pleasantness: 0.2, intensity: 0.55, control: 0.5, clarity: 0.6),
        Emotion(name: "Guilty",
                color: ColorData.calculateMoodColor(pleasantness: 0.25, intensity: 0.5) ?? .gray,
                description: "Feeling remorse and responsibility for a perceived wrongdoing, a weight on your conscience.",
                pleasantness: 0.25, intensity: 0.5, control: 0.4, clarity: 0.7),
        Emotion(name: "Troubled",
                color: ColorData.calculateMoodColor(pleasantness: 0.3, intensity: 0.5) ?? .gray,
                description: "Uneasy, your mind wrestles with nagging worries, a quiet storm clouding your calm.",
                pleasantness: 0.3, intensity: 0.5, control: 0.5, clarity: 0.6),
        Emotion(name: "Nervous",
                color: ColorData.calculateMoodColor(pleasantness: 0.32, intensity: 0.6) ?? .gray,
                description: "Jittery with unease, your mind buzzes with worry, anticipating challenges ahead.",
                pleasantness: 0.32, intensity: 0.6, control: 0.4, clarity: 0.6),
        Emotion(name: "Disappointed",
                color: ColorData.calculateMoodColor(pleasantness: 0.35, intensity: 0.5) ?? .gray,
                description: "Let down by unmet hopes, a sinking feeling settles in, dimming your expectations.",
                pleasantness: 0.35, intensity: 0.5, control: 0.6, clarity: 0.7),
        Emotion(name: "Irritated",
                color: ColorData.calculateMoodColor(pleasantness: 0.4, intensity: 0.55) ?? .gray,
                description: "Annoyed by small frustrations, a prickly edge sharpens your mood, testing patience.",
                pleasantness: 0.4, intensity: 0.55, control: 0.5, clarity: 0.8),
        Emotion(name: "Calm",
                color: ColorData.calculateMoodColor(pleasantness: 0.5, intensity: 0.4) ?? .gray,
                description: "At ease, your mind is steady, a gentle balance holding you in quiet serenity.",
                pleasantness: 0.5, intensity: 0.4, control: 0.8, clarity: 0.9),
        Emotion(name: "Content",
                color: ColorData.calculateMoodColor(pleasantness: 0.55, intensity: 0.45) ?? .gray,
                description: "Satisfied with the moment, a soft warmth of peace settles over you, untroubled.",
                pleasantness: 0.55, intensity: 0.45, control: 0.7, clarity: 0.8),
        Emotion(name: "Challenged",
                color: ColorData.calculateMoodColor(pleasantness: 0.6, intensity: 0.6) ?? .gray,
                description: "Sparked by a test, your focus sharpens, eager to push your limits and grow.",
                pleasantness: 0.6, intensity: 0.6, control: 0.6, clarity: 0.8),
        Emotion(name: "Pleased",
                color: ColorData.calculateMoodColor(pleasantness: 0.65, intensity: 0.45) ?? .gray,
                description: "Feeling happy and satisfied by an outcome or situation, a light and agreeable feeling.",
                pleasantness: 0.65, intensity: 0.45, control: 0.7, clarity: 0.8),
        Emotion(name: "Hopeful",
                color: ColorData.calculateMoodColor(pleasantness: 0.7, intensity: 0.5) ?? .gray,
                description: "Lifted by possibility, your heart lightens with optimism for what lies ahead.",
                pleasantness: 0.7, intensity: 0.5, control: 0.7, clarity: 0.8),
        Emotion(name: "Accomplished",
                color: ColorData.calculateMoodColor(pleasantness: 0.75, intensity: 0.55) ?? .gray,
                description: "Proud of your success, a glow of fulfillment warms you after reaching your goal.",
                pleasantness: 0.75, intensity: 0.55, control: 0.8, clarity: 0.9),
        Emotion(name: "Affectionate",
                color: ColorData.calculateMoodColor(pleasantness: 0.78, intensity: 0.5) ?? .gray,
                description: "Feeling warmth, tenderness, and care towards someone or something, a gentle connection.",
                pleasantness: 0.78, intensity: 0.5, control: 0.7, clarity: 0.8),
        Emotion(name: "Grateful",
                color: ColorData.calculateMoodColor(pleasantness: 0.85, intensity: 0.5) ?? .gray,
                description: "Heart warmed by appreciation, a deep sense of thankfulness grounds you in joy.",
                pleasantness: 0.85, intensity: 0.5, control: 0.8, clarity: 0.9),
        Emotion(name: "Blissful",
                color: ColorData.calculateMoodColor(pleasantness: 0.9, intensity: 0.55) ?? .gray,
                description: "Wrapped in pure joy, a radiant lightness fills you, every moment glowing with ease.",
                pleasantness: 0.9, intensity: 0.55, control: 0.7, clarity: 0.8)
    ]
    
    static let lowEnergyEmotions: [Emotion] = [
        Emotion(name: "Miserable",
                color: ColorData.calculateMoodColor(pleasantness: 0.1, intensity: 0.3) ?? .gray,
                description: "Sunk in deep sorrow, a heavy ache drains all light, leaving only despair.",
                pleasantness: 0.1, intensity: 0.3, control: 0.3, clarity: 0.5),
        Emotion(name: "Ashamed",
                color: ColorData.calculateMoodColor(pleasantness: 0.12, intensity: 0.4) ?? .gray,
                description: "Feeling deep distress and humiliation from a perceived flaw or wrongdoing, wanting to hide.",
                pleasantness: 0.12, intensity: 0.4, control: 0.2, clarity: 0.6),
        Emotion(name: "Depressed",
                color: ColorData.calculateMoodColor(pleasantness: 0.15, intensity: 0.35) ?? .gray,
                description: "Trapped in a fog of hopelessness, energy sapped, the world feels gray and distant.",
                pleasantness: 0.15, intensity: 0.35, control: 0.4, clarity: 0.4),
        Emotion(name: "Lonely",
                color: ColorData.calculateMoodColor(pleasantness: 0.18, intensity: 0.38) ?? .gray,
                description: "Feeling isolated and disconnected from others, a yearning for companionship or understanding.",
                pleasantness: 0.18, intensity: 0.38, control: 0.3, clarity: 0.6),
        Emotion(name: "Burned Out",
                color: ColorData.calculateMoodColor(pleasantness: 0.2, intensity: 0.3) ?? .gray,
                description: "Exhausted and empty, motivation gone, every task feels like an insurmountable weight.",
                pleasantness: 0.2, intensity: 0.3, control: 0.3, clarity: 0.5),
        Emotion(name: "Sad",
                color: ColorData.calculateMoodColor(pleasantness: 0.22, intensity: 0.4) ?? .gray,
                description: "Feeling sorrow or unhappiness, often with a sense of loss or disappointment, a quiet ache.",
                pleasantness: 0.22, intensity: 0.4, control: 0.5, clarity: 0.7),
        Emotion(name: "Apathetic",
                color: ColorData.calculateMoodColor(pleasantness: 0.25, intensity: 0.25) ?? .gray,
                description: "Numb to the world, nothing sparks interest, a dull void where feelings should be.",
                pleasantness: 0.25, intensity: 0.25, control: 0.5, clarity: 0.6),
        Emotion(name: "Listless",
                color: ColorData.calculateMoodColor(pleasantness: 0.3, intensity: 0.3) ?? .gray,
                description: "Drifting without purpose, energy low, a quiet disinterest cloaks your thoughts.",
                pleasantness: 0.3, intensity: 0.3, control: 0.6, clarity: 0.6),
        Emotion(name: "Tired",
                color: ColorData.calculateMoodColor(pleasantness: 0.32, intensity: 0.28) ?? .gray,
                description: "Lacking physical or mental energy, feeling weary and in need of rest, a sense of depletion.",
                pleasantness: 0.32, intensity: 0.28, control: 0.4, clarity: 0.8),
        Emotion(name: "Bored",
                color: ColorData.calculateMoodColor(pleasantness: 0.35, intensity: 0.35) ?? .gray,
                description: "Restless in monotony, craving something new, time drags in a haze of disengagement.",
                pleasantness: 0.35, intensity: 0.35, control: 0.5, clarity: 0.7),
        Emotion(name: "Carefree",
                color: ColorData.calculateMoodColor(pleasantness: 0.5, intensity: 0.3) ?? .gray,
                description: "Light and unburdened, worries slip away, leaving a gentle ease in the moment.",
                pleasantness: 0.5, intensity: 0.3, control: 0.7, clarity: 0.8),
        Emotion(name: "Relaxed",
                color: ColorData.calculateMoodColor(pleasantness: 0.55, intensity: 0.3) ?? .gray,
                description: "At peace, tension melts away, a soft calm settles over body and mind.",
                pleasantness: 0.55, intensity: 0.3, control: 0.8, clarity: 0.8),
        Emotion(name: "Secure",
                color: ColorData.calculateMoodColor(pleasantness: 0.65, intensity: 0.35) ?? .gray,
                description: "Safe and steady, a quiet confidence anchors you in a sense of stability.",
                pleasantness: 0.65, intensity: 0.35, control: 0.8, clarity: 0.9),
        Emotion(name: "Satisfied",
                color: ColorData.calculateMoodColor(pleasantness: 0.75, intensity: 0.35) ?? .gray,
                description: "Content with what is, a warm fulfillment glows, no need for more than this moment.",
                pleasantness: 0.75, intensity: 0.35, control: 0.7, clarity: 0.8),
        Emotion(name: "Serene",
                color: ColorData.calculateMoodColor(pleasantness: 0.85, intensity: 0.3) ?? .gray,
                description: "Deeply tranquil, a still lake of calm reflects clarity and quiet joy within.",
                pleasantness: 0.85, intensity: 0.3, control: 0.9, clarity: 0.9),
        Emotion(name: "Blessed",
                color: ColorData.calculateMoodColor(pleasantness: 0.9, intensity: 0.35) ?? .gray,
                description: "Filled with gratitude, a gentle warmth of fortune embraces you, heart full.",
                pleasantness: 0.9, intensity: 0.35, control: 0.8, clarity: 0.9)
    ]
}

