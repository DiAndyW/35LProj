// MARK: - Payload Structs for API Communication

// For sending coordinates to the backend
struct CheckInCoordinatesPayload: Codable {
    let latitude: Double
    let longitude: Double
}

// Represents the GeoJSON "coordinates" object in your Mongoose schema
struct GeoJSONPointData: Codable {
    let type: String // This will be "Point"
    let coordinates: [Double]  // Array of [longitude, latitude]

    // Initializer to ensure 'type' is always "Point"
    init(coordinates: [Double]) {
        self.type = "Point"
        self.coordinates = coordinates
    }
}

// This is your main location payload structure to send to the backend
struct CheckInLocationPayload: Codable {
    let landmarkName: String?
    let coordinates: GeoJSONPointData? // This will now hold the GeoJSON object
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
