//
//  MoodPost.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
import Foundation
import SwiftUICore

struct MoodPost: Codable, Identifiable {
    let id: String
    let userId: String
    let emotion: EmotionData
    let reason: String?
    let people: [String]?
    let activities: [String]?
    let privacy: String
    let location: LocationData?
    let timestamp: String
    let isAnonymous: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, emotion, reason, people, activities, privacy, location, timestamp, isAnonymous, createdAt, updatedAt
    }
}

extension MoodPost {
    func toFeedItem() -> FeedItem {
        print("\n--- Starting MoodPost to FeedItem Conversion for MoodPost ID: \(self.id) ---")
        
        // 1. Print source MoodPost details (optional, but good for context)
        print("[MoodPost Source] User ID: \(self.userId)")
        print("[MoodPost Source] Timestamp: \(self.timestamp)")
        print("[MoodPost Source] Emotion Name: \(self.emotion.name)")
        print("[MoodPost Source] Emotion Attributes: \(String(describing: self.emotion.attributes?.mapValues { $0.value }))")
        // EmotionData calculates its own color via its init(from: Decoder) or other inits.
        // This color is based on its own attributes.
        print("[MoodPost Source] EmotionData's own calculated color: \(String(describing: self.emotion.color))")
        print("[MoodPost Source] Reason/Content: \(self.reason ?? "N/A")")
        print("[MoodPost Source] People: \(self.people?.joined(separator: ", ") ?? "N/A")")
        print("[MoodPost Source] Activities: \(self.activities?.joined(separator: ", ") ?? "N/A")")
        if let loc = self.location {
            print("[MoodPost Source] Location Name: \(loc.name ?? "N/A")")
        } else {
            print("[MoodPost Source] Location: N/A")
        }
        
        // 2. Extract emotion attributes for SimpleEmotion conversion
        print("\n[SimpleEmotion Conversion] Extracting attributes from MoodPost.emotion.attributes:")
        let pleasantnessDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "pleasantness")
        let intensityDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "intensity")
        let clarityDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "clarity")
        let controlDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "control")
        
        // 3. Calculate color for SimpleEmotion
        print("\n[SimpleEmotion Conversion] Calculating color for SimpleEmotion:")
        print("[SimpleEmotion Conversion] Using Pleasantness: \(String(describing: pleasantnessDouble)), Intensity: \(String(describing: intensityDouble)) for color calculation.")
        
        var calculatedColorForSimpleEmotion: Color? = nil
        if let pValue = pleasantnessDouble, let iValue = intensityDouble {
            if let gradientColors = ColorData.getStartEndColors(forIntensity: iValue) {
                print("[SimpleEmotion Conversion] Determined Gradient: START \(gradientColors.startColor), END \(gradientColors.endColor) (for intensity: \(iValue))")
                calculatedColorForSimpleEmotion = ColorData.interpolateColor(
                    pleasantness: pValue,
                    startColor: gradientColors.startColor,
                    endColor: gradientColors.endColor
                )
                print("[SimpleEmotion Conversion] Interpolated Color for SimpleEmotion: \(String(describing: calculatedColorForSimpleEmotion))")
            } else {
                print("[SimpleEmotion Conversion] Could not determine gradient colors for intensity: \(iValue). SimpleEmotion color will be nil.")
            }
        } else {
            print("[SimpleEmotion Conversion] Pleasantness or Intensity is nil. SimpleEmotion color will be nil.")
        }
        
        // 4. Create SimpleEmotion instance
        print("\n[SimpleEmotion Conversion] Creating SimpleEmotion instance:")
        let simpleEmotionName = self.emotion.name // As per your struct, SimpleEmotion.name is non-optional
        let pleasantnessFloat = pleasantnessDouble != nil ? Float(pleasantnessDouble!) : nil
        let intensityFloat = intensityDouble != nil ? Float(intensityDouble!) : nil
        let clarityFloat = clarityDouble != nil ? Float(clarityDouble!) : nil
        let controlFloat = controlDouble != nil ? Float(controlDouble!) : nil
        
        let simpleEmotion = SimpleEmotion(
            name: simpleEmotionName,
            pleasantness: pleasantnessFloat,
            intensity: intensityFloat,
            clarity: clarityFloat,
            control: controlFloat,
            color: calculatedColorForSimpleEmotion
        )
        
        // 5. Convert LocationData to SimpleLocation
        print("\n[SimpleLocation Conversion] Converting LocationData:")
        let simpleLocation: SimpleLocation?
        if let locData = self.location {
            print("[SimpleLocation Conversion] Source LocationData Name: \(locData.name ?? "N/A")")
            simpleLocation = SimpleLocation(name: locData.name)
        } else {
            print("[SimpleLocation Conversion] Source LocationData is nil.")
            simpleLocation = nil
        }
        print("[SimpleLocation Conversion] Created SimpleLocation: Name: \(simpleLocation?.name ?? "N/A")")
        
        // 6. Create and return the FeedItem
        print("\n[FeedItem Creation] Creating final FeedItem:")
        print("[FeedItem Creation] ID: \(self.id)")
        print("[FeedItem Creation] UserID: \(self.userId)")
        // SimpleEmotion details already printed above during its creation
        print("[FeedItem Creation] Emotion (SimpleEmotion object): \(simpleEmotion)")
        print("[FeedItem Creation] Content (from MoodPost.reason): \(self.reason ?? "N/A")")
        print("[FeedItem Creation] People: \(self.people?.joined(separator: ", ") ?? "N/A")")
        print("[FeedItem Creation] Activities: \(self.activities?.joined(separator: ", ") ?? "N/A")")
        print("[FeedItem Creation] Location (SimpleLocation object): \(String(describing: simpleLocation))")
        print("[FeedItem Creation] Timestamp: \(self.timestamp)")
        
        let feedItem = FeedItem(
            id: self.id,
            userId: self.userId,
            emotion: simpleEmotion, // This is non-optional SimpleEmotion in FeedItem
            content: self.reason,   // Mapping reason to content
            people: self.people,
            activities: self.activities,
            location: simpleLocation,
            timestamp: self.timestamp
        )
        
        return feedItem
    }
}

struct EmotionData: Codable {
    let name: String
    let attributes: [String: AttributeValue]?
    let color: Color?
    
    init(name: String, attributes: [String: AttributeValue]?, color: Color?) {
        self.name = name
        self.attributes = attributes
        self.color = color
    }
    
    enum CodingKeys: String, CodingKey {
        case name, attributes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.attributes = try container.decodeIfPresent([String: AttributeValue].self, forKey: .attributes)
        let pleasantnessValue = AttributeValue.getAttributeAsDouble(from: self.attributes, forKey: "pleasantness")
        let intensityValue = AttributeValue.getAttributeAsDouble(from: self.attributes, forKey: "intensity")
        self.color = AttributeValue.calculateColor(pleasantness: pleasantnessValue, intensity: intensityValue)
    }
}

struct AttributeValue: Codable {
    let value: Any?
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { value = nil }
        else if let doubleVal = try? container.decode(Double.self) { value = doubleVal }
        else { throw DecodingError.typeMismatch(AttributeValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported attribute type or value was not an expected primitive (Double).")) }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value == nil { try container.encodeNil() }
        else if let doubleVal = value as? Double { try container.encode(doubleVal) }
        else { throw EncodingError.invalidValue(value ?? "nil", EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported attribute type for encoding (expected Double)")) }
    }
    init(_ doubleValue: Double?) { self.value = doubleValue }
    
    static func calculateColor(pleasantness: Double?, intensity: Double?) -> Color? {
        guard let pValue = pleasantness, let iValue = intensity else {
            return nil
        }
        guard let gradientColors = ColorData.getStartEndColors(forIntensity: iValue) else {
            return nil
        }
        return ColorData.interpolateColor(
            pleasantness: pValue,
            startColor: gradientColors.startColor,
            endColor: gradientColors.endColor
        )
    }
    static func getAttributeAsDouble(from attributes: [String: AttributeValue]?, forKey key: String) -> Double? {
        guard let attributeAnyValue = attributes?[key]?.value else { return nil }
        if let doubleValue = attributeAnyValue as? Double { return doubleValue }
        if let intValue = attributeAnyValue as? Int { return Double(intValue) }
        return nil
    }}

struct ColorData: Codable {
    //High energy
    private static let rageColor = (r: 208.0/255.0, g: 0.0/255.0, b: 0.0/255.0) // D00000
    private static let euphoricColor = (r: 255.0/255.0, g: 215/255.0, b: 0.0/255.0) // FFBA08 (Original was FFBA08, using FFD700 for Gold as in example)
    
    //Mediym energy
    private static let disgustedColor = (r: 111.0/255.0, g: 45.0/255.0, b: 189.0/255.0) // #6F2DBD
    private static let blissfulColor = (r: 185.0/255.0, g: 250.0/255.0, b: 248.0/255.0) // #B9FAF8
    
    //Low energy
    private static let miserableColor = (r: 34.0/255.0, g: 87.0/255.0, b: 122.0/255.0) // #22577A
    private static let blessedColor = (r: 128.0/255.0, g: 237.0/255.0, b: 153.0/255.0) // #80ED99
    
    static func interpolateColor(pleasantness: Double, startColor: (r: Double, g: Double, b: Double), endColor: (r: Double, g: Double, b: Double)) -> Color {
        let t = pleasantness // pleasantness is already 0.0 to 1.0
        let r = startColor.r + (endColor.r - startColor.r) * t
        let g = startColor.g + (endColor.g - startColor.g) * t
        let b = startColor.b + (endColor.b - startColor.b) * t
        return Color(red: r, green: g, blue: b)
    }
    
    static func getStartEndColors(forIntensity intensity: Double?) -> (startColor: (r: Double, g: Double, b: Double), endColor: (r: Double, g: Double, b: Double))? {
        guard let intensityValue = intensity else {
            return nil // Or return a default gradient if intensity is unknown
        }
        
        if intensityValue >= 0.7 { // High energy
            return (startColor: rageColor, endColor: euphoricColor)
        } else if intensityValue >= 0.4 && intensityValue < 0.7 { // Medium energy
            return (startColor: disgustedColor, endColor: blissfulColor)
        } else if intensityValue < 0.4 { // Low energy
            return (startColor: miserableColor, endColor: blessedColor)
        } else {
            return nil
        }
    }
}

struct LocationData: Codable {
    let name: String?
    let coordinates: [Double]?
    let isShared: Bool?
}

struct SimpleEmotion {
    let name: String
    let pleasantness: Float?
    let intensity: Float?
    let clarity: Float?
    let control: Float?
    let color: Color?
    
    init(name: String, pleasantness: Float?, intensity: Float?, clarity: Float?, control: Float?, color: Color?) {
        self.name = name
        self.pleasantness = pleasantness
        self.intensity = intensity
        self.clarity = clarity
        self.control = control
        self.color = color
    }
}

struct SimpleLocation {
    let name: String?
}

struct FeedItem: Identifiable {
    let id: String
    let userId: String
    let emotion: SimpleEmotion
    let content: String?
    let people: [String]?
    let activities: [String]?
    let location: SimpleLocation?
    let timestamp: String
}
