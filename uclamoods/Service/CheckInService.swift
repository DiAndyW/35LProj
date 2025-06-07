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

extension String {
    func nilIfEmpty() -> String? {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - CheckInService Class
class CheckInService {
    static func createCheckIn(
        emotion: Emotion,
        reasonText: String,
        socialTags: Set<String>,
        selectedActivities: Set<ActivityTag>,
        landmarkName: String?,
        userCoordinates: CLLocationCoordinate2D?,
        showLocation: Bool,
        privacySetting: CompleteCheckInView.PrivacySetting,
        userDataProvider: UserDataProvider
    ) async throws -> CreateCheckInResponsePayload {
        
        guard let userId = userDataProvider.currentUser?.id else {
            print("[CheckInService]: User ID not available.")
            throw CheckInServiceError.noUserIdAvailable
        }
        
        let emotionAttributes = CheckInEmotionAttributes(
            pleasantness: emotion.pleasantness,
            intensity: emotion.intensity,
            control: emotion.control,
            clarity: emotion.clarity
        )
        let emotionPayload = CheckInEmotionPayload(name: emotion.name, attributes: emotionAttributes)
        
        let peopleNames = Array(socialTags).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let activityNames = selectedActivities.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var locationAPIPayload: CheckInLocationPayload? = nil
        if showLocation { // 'showLocation' from the client view determines if location data is sent
            let nameForAPI = landmarkName?.nilIfEmpty()
            var geoJSONPointDataForAPI: GeoJSONPointData? = nil

            if let userCoords = userCoordinates {
                // Create the GeoJSONPointData object with [longitude, latitude]
                geoJSONPointDataForAPI = GeoJSONPointData(
                    coordinates: [userCoords.longitude, userCoords.latitude]
                )
            }

            // Only create the main location payload if there's a landmark name OR GeoJSON coordinate data
            if nameForAPI != nil || geoJSONPointDataForAPI != nil {
                locationAPIPayload = CheckInLocationPayload(
                    landmarkName: nameForAPI,
                    coordinates: geoJSONPointDataForAPI
                )
            }
        }
        
        let finalReason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let requestBody = CreateCheckInRequestPayload(
            userId: userId,
            emotion: emotionPayload,
            reason: finalReason.isEmpty ? nil : finalReason,
            people: peopleNames.isEmpty ? nil : peopleNames,
            activities: activityNames.isEmpty ? nil : activityNames,
            location: locationAPIPayload,
            privacy: privacySetting.rawValue.lowercased()
        )
        
        let url = Config.apiURL(for: "/api/checkin") // Ensure this path is correct
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded() // Your existing auth method
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(requestBody)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("[CheckInService]: Request body JSON: \(jsonString)")
            }
        } catch {
            print("[CheckInService]: Error encoding request body - \(error.localizedDescription)")
            throw CheckInServiceError.encodingFailed
        }
        
        print("[CheckInService]: Sending createCheckIn request to \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[CheckInService]: Invalid response from server (not HTTPResponse).")
                throw CheckInServiceError.unknownError
            }
            
            print("[CheckInService]: Received status code \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                print("[CheckInService]: Response body: \(responseString)")
            } else {
                print("[CheckInService]: Response body is empty.")
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let decoder = JSONDecoder()
                    let decodedResponse = try decoder.decode(CreateCheckInResponsePayload.self, from: data)
                    print("[CheckInService]: Check-in created successfully - Message: \"\(decodedResponse.message)\"")
                    return decodedResponse
                } catch {
                    print("[CheckInService]: Error decoding successful response - \(error.localizedDescription). Data: \(String(data: data, encoding: .utf8) ?? "nil")")
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
                    if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                        errorMessage = responseString
                    }
                    print("[CheckInService]: Could not decode backend error structure. Raw error: \(errorMessage)")
                }
                print("[CheckInService]: Server error - Status \(httpResponse.statusCode), Message: \(errorMessage)")
                throw CheckInServiceError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch let error as CheckInServiceError {
            throw error // Re-throw known errors
        } catch {
            print("[CheckInService]: Network or unknown error - \(error.localizedDescription)")
            throw CheckInServiceError.networkError(error)
        }
    }
}
