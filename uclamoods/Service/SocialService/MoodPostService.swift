import SwiftUI

enum MoodPostServiceError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
}

import Foundation

class MoodPostService {
    // Enhanced method with pagination parameters
    static func fetchMoodPosts(endpoint: String, completion: @escaping (Result<[MoodPost], MoodPostServiceError>) -> Void) {
        // Use the provided endpoint to construct the URL
        let url = Config.apiURL(for: endpoint)
        
        print("MoodPostService (user-specific): Fetching posts from \(url.absoluteString)") // Log the correct URL
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded() // Crucial for user-specific data
        
        // You'll need the URLSession.shared.dataTask logic here.
        // It's best to refactor the dataTask part into a private static method
        // that both fetchMoodPosts methods can call.
        performRequest(request: request, completion: completion)
    }
    
    // Private helper for the actual request (to avoid duplication)
    private static func performRequest(request: URLRequest, completion: @escaping (Result<[MoodPost], MoodPostServiceError>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    // Consider more specific error handling based on statusCode if available
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    // You might want to try and decode an error message from `data` here if it's a server error
                    completion(.failure(.serverError(statusCode: statusCode, message: "Invalid response or server error")))
                    return
                }
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                do {
                    let moodPosts = try JSONDecoder().decode([MoodPost].self, from: data)
                    completion(.success(moodPosts))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    // The original method for general feed (can also use performRequest)
    static func fetchMoodPosts(
        skip: Int = 0,
        limit: Int = 20,
        sort: String = "timestamp",
        completion: @escaping (Result<[MoodPost], MoodPostServiceError>) -> Void
    ) {
        guard var components = URLComponents(url: Config.apiURL(for: "/api/feed"), resolvingAgainstBaseURL: false) else {
            completion(.failure(.invalidURL))
            return
        }
        components.queryItems = [
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: sort)
        ]
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        print("MoodPostService (general feed): Fetching posts from \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded() // May or may not be needed for a general feed
        performRequest(request: request, completion: completion)
    }
}
