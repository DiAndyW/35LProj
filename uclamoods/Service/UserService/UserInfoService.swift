//
//  UserInfoService.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//

import SwiftUI
import Foundation

struct UsernameResponse: Codable {
    let username: String
}

struct ApiErrorResponse: Codable {
    let msg: String
}

enum FetchUserError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
            case .invalidURL: return "The server URL was invalid."
            case .networkError(let err): return "Network error: \(err.localizedDescription)"
            case .invalidResponse: return "Received an invalid response from the server."
            case .noData: return "No data was received from the server."
            case .decodingError(let err): return "Failed to understand the server's response: \(err.localizedDescription)"
            case .serverError(let statusCode, let message):
                return "Server error (\(statusCode)): \(message ?? "An unknown server error occurred.")"
        }
    }
}

func fetchUsername(for userId: String, completion: @escaping (Result<String, FetchUserError>) -> Void) {
    let endpoint = "/api/users/\(userId)/username"
    // Ensure Config.apiURL returns a non-optional URL or handle potential nil
    let url = Config.apiURL(for: endpoint)

    var request = URLRequest(url: url) // Create a URLRequest
    request.httpMethod = "GET" // Typically, fetching a username would be a GET request

    // Add the Authentication header
    request.addAuthenticationIfNeeded()

    // For debugging: Print the Authorization header
    if let authorizationHeader = request.value(forHTTPHeaderField: "Authorization") {
        print("fetchUsername: Authorization Header being sent: \(authorizationHeader)")
    } else {
        print("fetchUsername: Authorization Header is NOT set on the request.")
    }

    URLSession.shared.dataTask(with: request) { data, response, error in // Use the request object
        DispatchQueue.main.async {
            if let error = error {
                print("fetchUsername: Network error - \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("fetchUsername: Invalid response object received.")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("fetchUsername: Received HTTP status code \(httpResponse.statusCode) for URL: \(url.absoluteString)")


            guard let data = data else {
                print("fetchUsername: No data received from server.")
                completion(.failure(.noData))
                return
            }

            do {
                if (200...299).contains(httpResponse.statusCode) { // Success
                    let decodedResponse = try JSONDecoder().decode(UsernameResponse.self, from: data)
                    completion(.success(decodedResponse.username))
                } else { // Server-side error (4xx, 5xx)
                    // Attempt to decode your specific error structure
                    // If this fails, it will fall into the generic catch block
                    print("fetchUsername: Attempting to decode error response for status \(httpResponse.statusCode).")
                    if let errorString = String(data: data, encoding: .utf8) {
                         print("fetchUsername: Raw error data: \(errorString)")
                    }
                    let errorResponse = try JSONDecoder().decode(ApiErrorResponse.self, from: data)
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: errorResponse.msg)))
                }
            } catch let decodingError {
                print("fetchUsername: Decoding error - \(decodingError.localizedDescription). Status code: \(httpResponse.statusCode)")
                 if let responseString = String(data: data, encoding: .utf8) {
                    print("fetchUsername: Raw response data string that failed decoding: \(responseString)")
                }
                completion(.failure(.decodingError(decodingError)))
            }
        }
    }.resume()
}
