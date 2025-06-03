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
            simpleLocation = SimpleLocation(name: locData.name)
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
