//
//  ProfileService.swift
//  uclamoods
//
//  Created by David Sun on 6/1/25.
//
import SwiftUI

enum ProfileServiceError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
}


class ProfileService {
    
    static func fetchSummary() async throws -> UserSummary {
        let url = Config.apiURL(for: "/profile/summary")
        
        print("[ProfileService]: Fetching summary from \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[ProfileService]: Invalid response object received.")
            throw ProfileServiceError.invalidResponse
        }
        
        print("[ProfileService]: Received HTTP status code \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var serverMessage: String? = "Unknown server error."
            if let errorMessage = String(data: data, encoding: .utf8) {
                serverMessage = errorMessage
                print("[ProfileService]: Server error message - \(errorMessage)")
            }
            throw ProfileServiceError.serverError(statusCode: httpResponse.statusCode, message: serverMessage)
        }
        
        do {
            let decoder = JSONDecoder()
            let decodedResponseObject = try decoder.decode(UserSummary.self, from: data)
            
            if decodedResponseObject.success {
                let userProfileData = decodedResponseObject.data
                print("[ProfileService]: Username: \(userProfileData.username)")
                if let firstRecentCheckinEmotionName = userProfileData.recentCheckins.first?.emotion.name {
                    print("[ProfileService]: First recent check-in emotion name: \(firstRecentCheckinEmotionName)")
                }
                return decodedResponseObject
            } else {
                print("[ProfileService]: Server responded with success: false.")
                throw ProfileServiceError.serverError(statusCode: httpResponse.statusCode, message: "Profile summary retrieval indicated failure (success: false).")
            }
            
        } catch let decodingError {
            print("[ProfileService]: JSON decoding error - \(decodingError.localizedDescription)")
            if let decodingError = decodingError as? DecodingError {
                switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("[ProfileService]: Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("[ProfileService]: Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("[ProfileService]: Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("[ProfileService]: Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                    @unknown default:
                        print("[ProfileService]: Unknown decoding error.")
                }
            }
            throw ProfileServiceError.decodingError(decodingError)
        }
    }
}
