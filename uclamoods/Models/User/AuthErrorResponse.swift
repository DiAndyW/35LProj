import Foundation

public struct AuthErrorResponse: Codable {
    public let msg: String
    public let details: String?
} 