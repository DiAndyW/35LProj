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
    
    static func fetchSummary(completion: @escaping (Result<UserSummary, ProfileServiceError>) -> Void) {
        let url = Config.apiURL(for: "/profile/summary")
        
        print("ProfileService: Fetching summary from \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("ProfileService: Network request error - \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ProfileService: Invalid response object received.")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("ProfileService: Received HTTP status code \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                var serverMessage: String? = "Unknown server error."
                if let responseData = data, let errorMessage = String(data: responseData, encoding: .utf8) {
                    serverMessage = errorMessage
                    print("ProfileService: Server error message - \(errorMessage)")
                }
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: serverMessage)))
                return
            }
            
            guard let data = data else {
                print("ProfileService: No data received from server.")
                completion(.failure(.noData))
                return
            }
            do {
                let decoder = JSONDecoder()
                let decodedResponseObject = try decoder.decode(UserSummary.self, from: data)
                
                if decodedResponseObject.success {
                    let userProfileData = decodedResponseObject.data
                    print("Username: \(userProfileData.username)")
                    if let firstRecentCheckinEmotionName = userProfileData.recentCheckins.first?.emotion.name {
                        print("First recent check-in emotion name: \(firstRecentCheckinEmotionName)")
                    }
                    completion(.success(decodedResponseObject))
                } else {
                    print("ProfileService: Server responded with success: false.")
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: "Profile summary retrieval indicated failure (success: false).")))
                }
                
            } catch let decodingError {
                print("ProfileService: JSON decoding error - \(decodingError.localizedDescription)") // Corrected
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("  Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("  Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("  Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("  Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                        @unknown default:
                            print("  Unknown decoding error.")
                    }
                }
                completion(.failure(.decodingError(decodingError)))
            }
        }.resume()
    }
}
