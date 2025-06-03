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
    let isAnonymous: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, emotion, reason, people, activities, privacy, location, timestamp, isAnonymous, createdAt, updatedAt
    }
    
    func toFeedItem() -> FeedItem {
        let pleasantnessDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "pleasantness")
        let intensityDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "intensity")
        let clarityDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "clarity")
        let controlDouble = AttributeValue.getAttributeAsDouble(from: self.emotion.attributes, forKey: "control")
        
        let calculatedColorForSimpleEmotion = ColorData.calculateMoodColor(pleasantness: pleasantnessDouble, intensity: intensityDouble)
        
        let simpleEmotion = SimpleEmotion(
            name: self.emotion.name,
            pleasantness: pleasantnessDouble != nil ? Float(pleasantnessDouble!) : nil,
            intensity: intensityDouble != nil ? Float(intensityDouble!) : nil,
            clarity: clarityDouble != nil ? Float(clarityDouble!) : nil,
            control: controlDouble != nil ? Float(controlDouble!) : nil,
            color: calculatedColorForSimpleEmotion
        )
        
        let simpleLocation: SimpleLocation?
        if let locData = self.location {
            simpleLocation = SimpleLocation(name: locData.landmarkName)
        } else {
            simpleLocation = nil
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
            likesCount: 0,
            commentsCount: 0
        )
    }
}

struct EmotionData: Codable {
    let name: String
    let attributes: [String: AttributeValue]?
    let color: Color?
    
    init(name: String, attributes: [String: AttributeValue]?, color: Color? = nil) {
        self.name = name
        self.attributes = attributes
        if let color = color {
            self.color = color
        } else {
            let pleasantnessValue = AttributeValue.getAttributeAsDouble(from: attributes, forKey: "pleasantness")
            let intensityValue = AttributeValue.getAttributeAsDouble(from: attributes, forKey: "intensity")
            self.color = ColorData.calculateMoodColor(pleasantness: pleasantnessValue, intensity: intensityValue)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case name, attributes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.attributes = try container.decodeIfPresent([String: AttributeValue].self, forKey: .attributes)
        
        // Derive color using ColorData
        let pleasantnessValue = AttributeValue.getAttributeAsDouble(from: self.attributes, forKey: "pleasantness")
        let intensityValue = AttributeValue.getAttributeAsDouble(from: self.attributes, forKey: "intensity")
        self.color = ColorData.calculateMoodColor(pleasantness: pleasantnessValue, intensity: intensityValue)
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
    let landmarkName: String? // Your Swift property name can stay the same
    let coordinatesData: CoordinatesObject
    let isShared: Bool? // Note: "isShared" is not in your new JSON snippet for location.
                        // If it's never sent, it will correctly be nil.

    var coordinates: [Double] { // Your computed property
        return coordinatesData.coordinates
    }

    enum CodingKeys: String, CodingKey {
        case landmarkName = "name" // Corrected: Map to JSON key "name"
        case coordinatesData = "coordinates"
        case isShared
    }
}

struct CoordinatesObject: Codable {
    let type: String
    let coordinates: [Double]

    // Define CodingKeys for when it's an object.
    // These are used by the custom init and the encoder.
    enum ObjectCodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    // Convenience initializer if you need to create this programmatically
    init(type: String = "Point", coordinates: [Double]) {
        self.type = type
        self.coordinates = coordinates
    }

    init(from decoder: Decoder) throws {
        // First, try to decode it as an object (the GeoJSON-like structure)
        // This will attempt to get a keyed container. If the JSON value is not an object, it will fail.
        if let container = try? decoder.container(keyedBy: ObjectCodingKeys.self) {
            // Check if keys exist before decoding to handle partial objects gracefully, if necessary.
            // For this specific structure, both are non-optional, so direct decoding is fine.
            self.type = try container.decode(String.self, forKey: .type)
            self.coordinates = try container.decode([Double].self, forKey: .coordinates)
        }
        // If decoding as an object fails (e.g., because the JSON value is an array),
        // then try to decode it as a simple array of Doubles using a single value container.
        else if let container = try? decoder.singleValueContainer(),
                  let coordsArray = try? container.decode([Double].self) {
            // If it's just an array, assume the type is "Point".
            // Adjust this logic if a different default or error handling is needed.
            self.type = "Point"
            self.coordinates = coordsArray
        }
        // If both attempts fail, the data is not in a format we can understand.
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Coordinates data for 'CoordinatesObject' is not a valid object with 'type' and 'coordinates' keys, nor a simple array of doubles."
            ))
        }
    }

    func encode(to encoder: Encoder) throws {
        // When encoding, always write it out as the full object structure
        // for consistency. This ensures predictable output if you ever send this object back to a server.
        var container = encoder.container(keyedBy: ObjectCodingKeys.self)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.coordinates, forKey: .coordinates)
    }
}


struct SimpleEmotion {
    let name: String
    let pleasantness: Float?
    let intensity: Float?
    let clarity: Float?
    let control: Float?
    let color: Color?
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
}
