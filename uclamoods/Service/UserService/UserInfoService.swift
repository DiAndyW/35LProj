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
    let url = Config.apiURL(for: endpoint)
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                if (200...299).contains(httpResponse.statusCode) { // Success
                    let decodedResponse = try JSONDecoder().decode(UsernameResponse.self, from: data)
                    completion(.success(decodedResponse.username))
                } else { // Server-side error (4xx, 5xx)
                    let errorResponse = try JSONDecoder().decode(ApiErrorResponse.self, from: data)
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: errorResponse.msg)))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
    }.resume()
}
