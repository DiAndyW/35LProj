//
//  CheckInService.swift
//  uclamoods
//
//  Created by David Sun on 6/2/25.
//

import Foundation

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

class CheckInService {
    static func createCheckIn(
        emotion: Emotion,
        reasonText: String,
        selectedUsers: Set<MockUser>,
        selectedActivities: Set<ActivityTag>,
        currentLocationName: String,
        showLocation: Bool,
        privacySetting: CompleteCheckInView.PrivacySetting,
        userDataProvider: UserDataProvider
    ) async throws -> CreateCheckInResponsePayload {
        
        guard let userId = userDataProvider.currentUser?.id else {
            print("CheckInService: Error - User ID not available.")
            throw CheckInServiceError.noUserIdAvailable
        }
        
        let emotionAttributes = CheckInEmotionAttributes(
            pleasantness: emotion.pleasantness,
            intensity: emotion.intensity,
            control: emotion.control,
            clarity: emotion.clarity
        )
        let emotionPayload = CheckInEmotionPayload(name: emotion.name, attributes: emotionAttributes)
        
        let peopleNames = selectedUsers.map { $0.name }.filter { !$0.isEmpty && $0.lowercased() != "by myself" }
        let activityNames = selectedActivities.map { $0.name }.filter { !$0.isEmpty }
        
        var locationPayload: CheckInLocationPayload?
        if showLocation {
            locationPayload = CheckInLocationPayload(name: currentLocationName.isEmpty ? nil : currentLocationName, coordinates: nil, isShared: true)
        } else {
            locationPayload = CheckInLocationPayload(name: nil, coordinates: nil, isShared: false)
        }
        
        let finalReason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let requestBody = CreateCheckInRequestPayload(
            userId: userId,
            emotion: emotionPayload,
            reason: finalReason.isEmpty ? nil : finalReason,
            people: peopleNames.isEmpty ? nil : peopleNames,
            activities: activityNames.isEmpty ? nil : activityNames,
            location: locationPayload,
            privacy: privacySetting.rawValue.lowercased()
        )
        
        let url = Config.apiURL(for: "/api/checkin")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded()
        
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("CheckInService: Request body JSON: \(jsonString)")
            }
        } catch {
            print("CheckInService: Error encoding request body - \(error.localizedDescription)")
            throw CheckInServiceError.encodingFailed
        }
        
        print("CheckInService: Sending createCheckIn request to \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("CheckInService: Invalid response from server.")
            throw CheckInServiceError.unknownError
        }
        
        print("CheckInService: Received status code \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("CheckInService: Response body: \(responseString)")
        }
        
        
        if (200...299).contains(httpResponse.statusCode) {
            do {
                let decodedResponse = try JSONDecoder().decode(CreateCheckInResponsePayload.self, from: data)
                print("CheckInService: Check-in created successfully - \(decodedResponse.message)")
                return decodedResponse
            } catch {
                print("CheckInService: Error decoding successful response - \(error.localizedDescription)")
                throw CheckInServiceError.decodingFailed
            }
        } else {
            var errorMessage = "An error occurred."
            if let errorData = try? JSONDecoder().decode(BackendErrorResponse.self, from: data) {
                errorMessage = errorData.error
                if let details = errorData.details {
                    errorMessage += " (\(details))"
                }
            } else if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                errorMessage = responseString
            }
            print("CheckInService: Server error - Status \(httpResponse.statusCode), Message: \(errorMessage)")
            throw CheckInServiceError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
}
