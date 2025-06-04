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
    let likes: LikesInfo?
    let comments: CommentsInfo?
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
            control: controlDouble != nil ? Float(controlDouble!) : nil
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
            likes: self.likes,
            comments: self.comments,
            likesCount: self.likes?.count ?? 0,
            commentsCount: self.comments?.count ?? 0
        )
    }
}

struct CommentPosts: Codable, Identifiable, Equatable {
    let id = UUID()
    let userId: String
    let content: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case userId
        case content, timestamp
    }
}

struct CommentsInfo: Codable, Equatable {
    let count: Int
    let data: [CommentPosts]
}

struct LikesInfo: Codable, Equatable {
    let count: Int
    let userIds: [String]
}

struct EmotionData: Codable {
    let name: String
    let attributes: [String: AttributeValue]?
    let color: Color?
    
    init(name: String, attributes: [String: AttributeValue]?, color: Color? = nil) {
        self.name = name
        self.attributes = attributes
        self.color = EmotionColorMap.getColor(for: name)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, attributes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.attributes = try container.decodeIfPresent([String: AttributeValue].self, forKey: .attributes)
        self.color = EmotionColorMap.getColor(for: self.name) //
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(attributes, forKey: .attributes)
    }
}
struct AttributeValue: Codable {
    let value: Double?
    
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
        try container.encode(self.value)
    }
    
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
struct RGBAColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init?(color: Color?) {
        guard let existingColor = color else { return nil }
#if canImport(UIKit)
        let platformColor = UIColor(existingColor)
#elseif canImport(AppKit)
        guard let platformColor = NSColor(existingColor).usingColorSpace(.sRGB) else {
            return nil
        }
#else
        return nil
#endif
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        platformColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.alpha = Double(a)
    }
    var swiftUIColor: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}


struct SimpleEmotion: Codable, Equatable {
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
        self.color = EmotionColorMap.getColor(for: name)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, pleasantness, intensity, clarity, control
        case colorData
    }
    static func == (lhs: SimpleEmotion, rhs: SimpleEmotion) -> Bool {
        return lhs.name == rhs.name &&
        lhs.pleasantness == rhs.pleasantness &&
        lhs.intensity == rhs.intensity &&
        lhs.clarity == rhs.clarity &&
        lhs.control == rhs.control &&
        lhs.color == rhs.color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        pleasantness = try container.decodeIfPresent(Float.self, forKey: .pleasantness)
        intensity = try container.decodeIfPresent(Float.self, forKey: .intensity)
        clarity = try container.decodeIfPresent(Float.self, forKey: .clarity)
        control = try container.decodeIfPresent(Float.self, forKey: .control)
        
        if let rgbaColor = try container.decodeIfPresent(RGBAColor.self, forKey: .colorData) {
            self.color = rgbaColor.swiftUIColor
        } else {
            self.color = EmotionColorMap.getColor(for: self.name) //
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(pleasantness, forKey: .pleasantness)
        try container.encodeIfPresent(intensity, forKey: .intensity)
        try container.encodeIfPresent(clarity, forKey: .clarity)
        try container.encodeIfPresent(control, forKey: .control)
        
        if let colorToEncode = self.color, let rgbaRepresentation = RGBAColor(color: colorToEncode) {
            try container.encode(rgbaRepresentation, forKey: .colorData)
        } else {
            try container.encodeNil(forKey: .colorData)
        }
    }
}

struct SimpleLocation: Equatable {
    let name: String?
}

struct FeedItem: Identifiable, Equatable {
    let id: String
    let userId: String
    let emotion: SimpleEmotion
    let content: String?
    let people: [String]?
    let activities: [String]?
    let location: SimpleLocation?
    let timestamp: String
    let likes: LikesInfo?
    let comments: CommentsInfo?
    let likesCount: Int?
    let commentsCount: Int?
}
