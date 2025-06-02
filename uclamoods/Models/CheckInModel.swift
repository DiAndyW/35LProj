//
//  CheckInModel.swift
//  uclamoods
//
//  Created by David Sun on 6/2/25.
//

import Foundation

struct CheckInEmotionAttributes: Codable {
    let pleasantness: Double
    let intensity: Double
    let control: Double
    let clarity: Double
}

struct CheckInEmotionPayload: Codable {
    let name: String
    let attributes: CheckInEmotionAttributes
}

struct CheckInLocationPayload: Codable {
    let name: String?
    let coordinates: [Double]?
    let isShared: Bool
}

struct CreateCheckInRequestPayload: Codable {
    let userId: String
    let emotion: CheckInEmotionPayload
    let reason: String?
    let people: [String]?
    let activities: [String]?
    let location: CheckInLocationPayload?
    let privacy: String
}

struct CreateCheckInResponsePayload: Codable {
    let message: String
}

struct BackendErrorResponse: Codable {
    let error: String
    let details: String?
    let received: BackendReceivedFields?
}

struct BackendReceivedFields: Codable {
    let userId: Bool?
    let emotion: Bool?
    let emotionName: Bool?
}
