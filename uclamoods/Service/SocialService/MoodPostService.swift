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
    static func fetchMoodPosts(
        skip: Int = 0,
        limit: Int = 20,
        sort: String = "timestamp", // "timestamp" or "hottest"
        completion: @escaping (Result<[MoodPost], MoodPostServiceError>) -> Void
    ) {
        // Construct URL with query parameters
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
        
        print("MoodPostService: Fetching posts from \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // ... rest of existing networking code
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(.invalidResponse))
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
    
    // Convenience method for backward compatibility
    static func fetchMoodPosts(endpoint: String, completion: @escaping (Result<[MoodPost], MoodPostServiceError>) -> Void) {
        fetchMoodPosts(skip: 0, limit: 20, sort: "timestamp", completion: completion)
    }
}
