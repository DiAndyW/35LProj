//
//  CommentService.swift
//  uclamoods
//
//  Created by David Sun on 6/3/25.
//

import Foundation

enum CommentServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
            case .invalidURL: return "The server URL for the comment service was invalid."
            case .networkError(let err): return "Network error during comment operation: \(err.localizedDescription)"
            case .invalidResponse: return "Received an invalid response from the comment service."
            case .noData: return "No data was received from the comment service."
            case .decodingError(let err): return "Failed to understand the comment service's response: \(err.localizedDescription)"
            case .serverError(let statusCode, let message):
                return "Comment service error (\(statusCode)): \(message ?? "An unknown server error occurred.")"
            case .encodingFailed: return "Failed to prepare comment data for the server."
        }
    }
}

struct AddCommentRequest: Codable {
    let userId: String
    let content: String
}

struct AddCommentResponse: Codable {
    let message: String
    let checkInId: String
    let comment: CommentPosts
    let commentsCount: Int
    let timestamp: String
}

class CommentService {
    static func addComment(
        postId: String,
        userId: String,
        content: String,
        completion: @escaping (Result<AddCommentResponse, CommentServiceError>) -> Void
    ) {
        let endpoint = "/api/checkin/\(postId)/comment"
        guard let url = URL(string: Config.baseURL.absoluteString + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("CommentService: Adding comment to post \(postId) by user \(userId) at \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthenticationIfNeeded()
        
        let requestBody = AddCommentRequest(userId: userId, content: content)
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("CommentService: Failed to encode request body - \(error.localizedDescription)")
            completion(.failure(.encodingFailed))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CommentService: Network request error - \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("CommentService: Invalid response object.")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("CommentService: Response status code \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("CommentService: No data received.")
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    if (200...299).contains(httpResponse.statusCode) {
                        let decodedResponse = try JSONDecoder().decode(AddCommentResponse.self, from: data)
                        print("CommentService: Comment added successfully. Post: \(decodedResponse.checkInId), New Count: \(decodedResponse.commentsCount)")
                        completion(.success(decodedResponse))
                    } else {
                        var serverMessage = "Failed to add comment."
                        if let errorDetail = try? JSONDecoder().decode(ErrorResponse.self, from: data).error {
                            serverMessage = errorDetail
                        } else if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                            serverMessage = errorString
                        }
                        print("CommentService: Server error (\(httpResponse.statusCode)): \(serverMessage)")
                        completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: serverMessage)))
                    }
                } catch let decodingError {
                    print("CommentService: JSON decoding error - \(decodingError.localizedDescription)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("CommentService: Raw response data string: \(responseString)")
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
