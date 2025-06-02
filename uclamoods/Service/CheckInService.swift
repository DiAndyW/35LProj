//
//  CheckInService.swift
//  uclamoods
//
//  Created by David Sun on 6/2/25.
//

import Foundation
import CoreLocation // Import CoreLocation

// MARK: - Error Enum (Keep your existing detailed error enum)
enum CheckInServiceError: LocalizedError {
    case encodingFailed
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case decodingFailed
    case noUserIdAvailable
    case unknownError
    
    var errorDescription: String? {
        switch self {
            case .encodingFailed:
                return "Failed to prepare data for the server."
            case .networkError(let error):
                return "Network request failed: \(error.localizedDescription)"
            case .serverError(let statusCode, let message):
                return "Server error (Status \(statusCode)): \(message ?? "An issue occurred on the server.")"
            case .decodingFailed:
                return "Failed to understand the server's response."
            case .noUserIdAvailable:
                return "Could not identify the current user. Please sign in again."
            case .unknownError:
                return "An unexpected error occurred."
        }
    }
}



// MARK: - CheckInService Class
class CheckInService {
    static func createCheckIn(
        emotion: Emotion, // Assuming Emotion struct/class has needed properties
        reasonText: String,
        selectedUsers: Set<MockUser>,
        selectedActivities: Set<ActivityTag>,
        landmarkName: String?, // Updated: Now the fetched landmark name
        userCoordinates: CLLocationCoordinate2D?, // New: Actual coordinates
        showLocation: Bool, // User's intent to share
        privacySetting: CompleteCheckInView.PrivacySetting,
        userDataProvider: UserDataProvider // Assuming this provides User ID and potentially auth token
    ) async throws -> CreateCheckInResponsePayload {
        
        guard let userId = userDataProvider.currentUser?.id else {
            print("CheckInService: Error - User ID not available.")
            throw CheckInServiceError.noUserIdAvailable
        }
        
        let emotionAttributes = CheckInEmotionAttributes(
            pleasantness: emotion.pleasantness, // Ensure your Emotion type has these
            intensity: emotion.intensity,
            control: emotion.control,
            clarity: emotion.clarity
        )
        let emotionPayload = CheckInEmotionPayload(name: emotion.name, attributes: emotionAttributes)
        
        let peopleNames = selectedUsers.map { $0.name }.filter { !$0.isEmpty && $0.lowercased() != "by myself" }
        let activityNames = selectedActivities.map { $0.name }.filter { !$0.isEmpty }
        
        var locationAPIPayload: CheckInLocationPayload? = nil
        if showLocation {
            var coordsPayload: CheckInCoordinatesPayload? = nil
            if let coords = userCoordinates {
                coordsPayload = CheckInCoordinatesPayload(latitude: coords.latitude, longitude: coords.longitude)
            }
            // Send location object only if there's something to send (landmark or coords)
            if landmarkName != nil || coordsPayload != nil {
                 locationAPIPayload = CheckInLocationPayload(
                    landmarkName: landmarkName?.isEmpty == false ? landmarkName : nil,
                    coordinates: coordsPayload
                )
            }
        }
        // If !showLocation, locationAPIPayload remains nil, so backend won't receive 'location' field or it'll be null.

        let finalReason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let requestBody = CreateCheckInRequestPayload(
            userId: userId,
            emotion: emotionPayload,
            reason: finalReason.isEmpty ? nil : finalReason,
            people: peopleNames.isEmpty ? nil : peopleNames,
            activities: activityNames.isEmpty ? nil : activityNames,
            location: locationAPIPayload, // Pass the structured location payload
            privacy: privacySetting.rawValue.lowercased()
        )
        
        // Assuming Config.apiURL and request.addAuthenticationIfNeeded() are defined elsewhere
        let url = Config.apiURL(for: "/api/checkin") // Ensure this path is correct
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded() // Your existing auth method
        
        do {
            let encoder = JSONEncoder()
            // Optional: Configure date encoding strategy if needed by your backend for any Date properties
            // encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(requestBody)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("CheckInService: Request body JSON: \(jsonString)")
            }
        } catch {
            print("CheckInService: Error encoding request body - \(error.localizedDescription)")
            throw CheckInServiceError.encodingFailed
        }
        
        print("CheckInService: Sending createCheckIn request to \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("CheckInService: Invalid response from server (not HTTPResponse).")
                throw CheckInServiceError.unknownError // Or a more specific network error
            }
            
            print("CheckInService: Received status code \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                print("CheckInService: Response body: \(responseString)")
            } else {
                print("CheckInService: Response body is empty.")
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let decoder = JSONDecoder()
                    // Optional: Configure date decoding strategy if needed
                    // decoder.dateDecodingStrategy = .iso8601
                    let decodedResponse = try decoder.decode(CreateCheckInResponsePayload.self, from: data)
                    print("CheckInService: Check-in created successfully - Message: \"\(decodedResponse.message)\"")
                    return decodedResponse
                } catch {
                    print("CheckInService: Error decoding successful response - \(error.localizedDescription). Data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw CheckInServiceError.decodingFailed
                }
            } else {
                var errorMessage = "An error occurred on the server."
                do {
                    let errorData = try JSONDecoder().decode(BackendErrorResponse.self, from: data)
                    errorMessage = errorData.error
                    if let details = errorData.details {
                        errorMessage += " (\(details))"
                    }
                } catch {
                    // If decoding the specific error fails, use a generic message or the raw response string
                    if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                        errorMessage = responseString
                    }
                     print("CheckInService: Could not decode backend error structure. Raw error: \(errorMessage)")
                }
                print("CheckInService: Server error - Status \(httpResponse.statusCode), Message: \(errorMessage)")
                throw CheckInServiceError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch let error as CheckInServiceError {
            throw error // Re-throw known errors
        } catch {
            // Catch other network errors (e.g., no internet connection)
            print("CheckInService: Network or unknown error - \(error.localizedDescription)")
            throw CheckInServiceError.networkError(error)
        }
    }
}
