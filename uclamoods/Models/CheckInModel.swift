// MARK: - Payload Structs for API Communication

// For sending coordinates to the backend
struct CheckInCoordinatesPayload: Codable {
    let latitude: Double
    let longitude: Double
}

// Updated location payload to include coordinates
struct CheckInLocationPayload: Codable {
    let name: String?          
    let coordinates: [Double]?
    let isShared: Bool
}

// Assuming these are already defined or you can create them:
struct CheckInEmotionAttributes: Codable { // If not already defined
    let pleasantness: Double?
    let intensity: Double?
    let control: Double?
    let clarity: Double?
}

struct CheckInEmotionPayload: Codable { // If not already defined
    let name: String
    let attributes: CheckInEmotionAttributes?
}

// Main request payload
struct CreateCheckInRequestPayload: Codable {
    let userId: String // Assuming your UserDataProvider.currentUser.id is a String
    let emotion: CheckInEmotionPayload
    let reason: String?
    let people: [String]?
    let activities: [String]?
    let location: CheckInLocationPayload? // Updated
    let privacy: String
}

// Response payload (assuming this matches your backend)
struct CreateCheckInResponsePayload: Codable {
    let message: String
    // Add other fields if your backend returns more data (e.g., the created check-in object)
}

// For decoding backend errors (assuming this structure)
struct BackendErrorResponse: Codable {
    let error: String
    let details: String?
}
