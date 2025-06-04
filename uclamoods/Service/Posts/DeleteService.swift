//
//  DeleteServiceError.swift
//  uclamoods
//
//  Created by Yang Gao on 6/4/25.
//


//
//  DeleteService.swift
//  uclamoods
//
//  Created by Assistant on 6/4/25.
//

import Foundation

enum DeleteServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case encodingFailed
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: 
            return "The server URL for the delete service was invalid."
        case .networkError(let err): 
            return "Network error during delete operation: \(err.localizedDescription)"
        case .invalidResponse: 
            return "Received an invalid response from the delete service."
        case .noData: 
            return "No data was received from the delete service."
        case .decodingError(let err): 
            return "Failed to understand the delete service's response: \(err.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Delete service error (\(statusCode)): \(message ?? "An unknown server error occurred.")"
        case .encodingFailed: 
            return "Failed to prepare delete data for the server."
        case .unauthorized:
            return "You are not authorized to delete this post."
        case .notFound:
            return "The post you're trying to delete was not found."
        }
    }
}

struct DeleteCheckInRequest: Codable {
    let userId: String
}

struct DeleteCheckInResponse: Codable {
    let message: String
    let deletedId: String
    let timestamp: String
}

class DeleteService {
    static func deletePost(
        postId: String,
        userId: String,
        completion: @escaping (Result<DeleteCheckInResponse, DeleteServiceError>) -> Void
    ) {
        let endpoint = "/api/checkin/\(postId)"
        guard let url = URL(string: Config.baseURL.absoluteString + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("DeleteService: Deleting post \(postId) by user \(userId) at \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded()
        
        let requestBody = DeleteCheckInRequest(userId: userId)
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("DeleteService: Failed to encode request body - \(error.localizedDescription)")
            completion(.failure(.encodingFailed))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DeleteService: Network request error - \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DeleteService: Invalid response object.")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("DeleteService: Response status code \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("DeleteService: No data received.")
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    switch httpResponse.statusCode {
                    case 200...299:
                        let decodedResponse = try JSONDecoder().decode(DeleteCheckInResponse.self, from: data)
                        print("DeleteService: Post deleted successfully. ID: \(decodedResponse.deletedId)")
                        completion(.success(decodedResponse))
                        
                    case 403:
                        print("DeleteService: Unauthorized to delete this post")
                        completion(.failure(.unauthorized))
                        
                    case 404:
                        print("DeleteService: Post not found")
                        completion(.failure(.notFound))
                        
                    default:
                        var serverMessage = "Failed to delete post."
                        if let errorDetail = try? JSONDecoder().decode(ErrorResponse.self, from: data).error {
                            serverMessage = errorDetail
                        } else if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                            serverMessage = errorString
                        }
                        print("DeleteService: Server error (\(httpResponse.statusCode)): \(serverMessage)")
                        completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: serverMessage)))
                    }
                } catch let decodingError {
                    print("DeleteService: JSON decoding error - \(decodingError.localizedDescription)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("DeleteService: Raw response data string: \(responseString)")
                    }
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
    
    private struct ErrorResponse: Codable {
        let error: String
        let details: String?
    }
}