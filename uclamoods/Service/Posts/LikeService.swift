//
//  LikeService.swift
//  uclamoods
//
//  Created by David Sun on 6/3/25.
//

import SwiftUI // Or Foundation if SwiftUI is not strictly needed here

// Define a specific error enum for LikeService
enum LikeServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
            case .invalidURL: return "The server URL for the like service was invalid."
            case .networkError(let err): return "Network error during like operation: \(err.localizedDescription)"
            case .invalidResponse: return "Received an invalid response from the like service."
            case .noData: return "No data was received from the like service."
            case .decodingError(let err): return "Failed to understand the like service's response: \(err.localizedDescription)"
            case .serverError(let statusCode, let message):
                return "Like service error (\(statusCode)): \(message ?? "An unknown server error occurred.")"
            case .encodingFailed: return "Failed to prepare data for the like service."
        }
    }
}

struct UpdateLikeResponse: Codable {
    let message: String
    let checkInId: String
    let likesCount: Int
    let timestamp: String
}

class LikeService {
    static func updateLikeStatus(for postId: String, userId: String, completion: @escaping (Result<UpdateLikeResponse, LikeServiceError>) -> Void) {
        let endpoint = "/api/checkin/\(postId)/like"
        guard let url = URL(string: Config.baseURL.absoluteString + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("LikeService: Updating like status for post \(postId) by user \(userId) at \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded()
        
        let requestBody = ["userId": userId]
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("LikeService: Failed to encode request body - \(error.localizedDescription)")
            completion(.failure(.encodingFailed))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("LikeService: Network request error - \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("LikeService: Invalid response object.")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("LikeService: Response status code \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("LikeService: No data received.")
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    if (200...299).contains(httpResponse.statusCode) {
                        let decodedResponse = try JSONDecoder().decode(UpdateLikeResponse.self, from: data)
                        print("LikeService: Like status updated. Post: \(decodedResponse.checkInId), Count: \(decodedResponse.likesCount)")
                        completion(.success(decodedResponse))
                    } else {
                        var serverMessage = "Failed to update like."
                        if let errorDetail = String(data: data, encoding: .utf8) {
                            serverMessage = errorDetail
                        }
                        print("LikeService: Server error (\(httpResponse.statusCode)): \(serverMessage)")
                        completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: serverMessage)))
                    }
                } catch let decodingError {
                    print("LikeService: JSON decoding error - \(decodingError.localizedDescription)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("LikeService: Raw response data string: \(responseString)")
                    }
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
}
