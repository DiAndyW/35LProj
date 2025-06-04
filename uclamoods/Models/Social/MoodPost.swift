//
//  MoodPost.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
//
import Foundation
import SwiftUI

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
    let likes: [String]?
    let comments: [PostComment]?
    let isAnonymous: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, emotion, reason, people, activities, privacy, location, timestamp, likes, comments, isAnonymous, createdAt, updatedAt
    }
    
    func toFeedItem() -> FeedItem {
        let pleasantnessDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "pleasantness")
        let intensityDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "intensity")
        let clarityDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "clarity")
        let controlDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "control")
        
        let simpleEmotion = SimpleEmotion(
            name: self.emotion.name,
            pleasantness: pleasantnessDouble != nil ? Float(pleasantnessDouble!) : nil,
            intensity: intensityDouble != nil ? Float(intensityDouble!) : nil,
            clarity: clarityDouble != nil ? Float(clarityDouble!) : nil,
            control: controlDouble != nil ? Float(controlDouble!) : nil,
        )
        
        let simpleLocation: SimpleLocation?
        if let locData = self.location {
            simpleLocation = SimpleLocation(name: locData.landmarkName)
        } else {
            simpleLocation = nil
        }
        
        var likesCount = 0
        for _ in likes ?? [] {
            likesCount+=1
        }
        
        var commentsCount = 0
        for _ in comments ?? [] {
            commentsCount+=1
        }
        
        return FeedItem(
            id: self.id,
            userId: self.userId,
            emotion: simpleEmotion,
            content: self.reason,
            people: self.people,
            activities: self.activities,
            location: simpleLocation,
            timestamp: self.timestamp,
            likesCount: likesCount,
            commentsCount: commentsCount,
            comments: self.comments
        )
    }
}

struct PostComment: Codable {
    let userID: String
    let content: String
    let timestamp: String
}

// MARK: - Updated EmotionData struct
struct EmotionData: Codable {
    let name: String
    let attributes: [String: AttributeValue]?
    let color: Color?
    
    init(name: String, attributes: [String: AttributeValue]?, color: Color? = nil) {
        self.name = name
        self.attributes = attributes
        // Use the emotion name to get color from map
        self.color = EmotionColorMap.getColor(for: name)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, attributes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.attributes = try container.decodeIfPresent([String: AttributeValue].self, forKey: .attributes)
        
        // Use the emotion name to get color from map instead of calculating
        self.color = EmotionColorMap.getColor(for: self.name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(attributes, forKey: .attributes)
    }
}

struct AttributeValue: Codable {
    let value: Double? // Changed from Any? to Double?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = nil
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else {
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Attribute value was not decodable as Double."))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Handles nil by encoding nil, otherwise encodes the double.
        try container.encode(self.value)
    }
    
    // Initializer for creating an AttributeValue programmatically
    init(_ doubleValue: Double?) {
        self.value = doubleValue
    }
    
    static func getAttributeAsDouble(from attributes: [String: AttributeValue]?, forKey key: String) -> Double? {
        return attributes?[key]?.value
    }
}

struct LocationData: Codable {
    let landmarkName: String?
    let coordinatesData: CoordinatesObject
    let isShared: Bool?

    var coordinates: [Double] {
        return coordinatesData.coordinates
    }

    enum CodingKeys: String, CodingKey {
        case landmarkName = "name"
        case coordinatesData = "coordinates"
        case isShared
    }
}

struct CoordinatesObject: Codable {
    let type: String
    let coordinates: [Double]

    enum ObjectCodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(type: String = "Point", coordinates: [Double]) {
        self.type = type
        self.coordinates = coordinates
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: ObjectCodingKeys.self) {
            self.type = try container.decode(String.self, forKey: .type)
            self.coordinates = try container.decode([Double].self, forKey: .coordinates)
        }
        else if let container = try? decoder.singleValueContainer(),
                  let coordsArray = try? container.decode([Double].self) {
            self.type = "Point"
            self.coordinates = coordsArray
        }
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Coordinates data for 'CoordinatesObject' is not a valid object with 'type' and 'coordinates' keys, nor a simple array of doubles."
            ))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ObjectCodingKeys.self)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.coordinates, forKey: .coordinates)
    }
}

// Helper struct to represent Color in a Codable way (RGBA components)
struct RGBAColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    // Initialize from SwiftUI.Color
    // Returns nil if color components cannot be extracted (e.g., on unsupported platforms or for invalid colors)
    init?(color: Color?) {
        guard let existingColor = color else { return nil }

        // Use UIColor (iOS/tvOS/watchOS/visionOS) or NSColor (macOS) to extract RGBA components
        #if canImport(UIKit)
            let platformColor = UIColor(existingColor)
        #elseif canImport(AppKit)
            // Ensure the NSColor is in a device-independent color space (e.g., sRGB) before extracting components
            guard let platformColor = NSColor(existingColor).usingColorSpace(.sRGB) else {
                // Fallback if color conversion fails
                // print("Warning: Could not convert NSColor to sRGB for serialization.")
                return nil
            }
        #else
            // Fallback for platforms where neither UIKit nor AppKit is available.
            // Direct component extraction from SwiftUI.Color is not universally supported.
            // print("Warning: Color serialization is not fully supported on this platform.")
            return nil // Or define a default/error color representation
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // Extract components
        #if canImport(UIKit) || canImport(AppKit)
            platformColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(a)
        #else
            // Should not be reached if the earlier #else for platformColor assignment returned nil
            return nil
        #endif
    }

    // Convert back to SwiftUI.Color
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct SimpleEmotion: Codable {
    let name: String
    let pleasantness: Float?
    let intensity: Float?
    let clarity: Float?
    let control: Float?
    let color: Color?

    init(name: String, pleasantness: Float?, intensity: Float?, clarity: Float?, control: Float?, color: Color? = nil) {
        self.name = name
        self.pleasantness = pleasantness
        self.intensity = intensity
        self.clarity = clarity
        self.control = control
        
        // Use the emotion name to get color from map
        self.color = EmotionColorMap.getColor(for: name)
    }

    enum CodingKeys: String, CodingKey {
        case name, pleasantness, intensity, clarity, control
        case colorData = "color"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        pleasantness = try container.decodeIfPresent(Float.self, forKey: .pleasantness)
        intensity = try container.decodeIfPresent(Float.self, forKey: .intensity)
        clarity = try container.decodeIfPresent(Float.self, forKey: .clarity)
        control = try container.decodeIfPresent(Float.self, forKey: .control)

        self.color = EmotionColorMap.getColor(for: self.name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(pleasantness, forKey: .pleasantness)
        try container.encodeIfPresent(intensity, forKey: .intensity)
        try container.encodeIfPresent(clarity, forKey: .clarity)
        try container.encodeIfPresent(control, forKey: .control)

        // Encode the color from the map
        if let existingColor = self.color {
            if let rgbaRepresentation = RGBAColor(color: existingColor) {
                try container.encode(rgbaRepresentation, forKey: .colorData)
            } else {
                try container.encodeNil(forKey: .colorData)
            }
        } else {
            try container.encodeNil(forKey: .colorData)
        }
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
    let likesCount: Int
    let commentsCount: Int
    let comments: [PostComment]?
}
