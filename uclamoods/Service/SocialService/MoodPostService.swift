import SwiftUI
import Foundation

enum FeedSortMethod: String, CaseIterable {
    case relevance = "relevance"
    case recent = "timestamp"
    case popular = "hottest"
    
    var displayName: String {
        switch self {
        case .relevance: return "For You"
        case .recent: return "Recent"
        case .popular: return "Popular"
        }
    }
    
    var icon: String {
        switch self {
        case .relevance: return "sparkles"
        case .recent: return "clock"
        case .popular: return "heart.fill"
        }
    }
}

enum MoodPostServiceError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
}

struct UserCheckInsPaginatedResponse: Codable {
    let data: [MoodPost]
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int
}

struct PaginationMetadata {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int
}

class MoodPostService {
    // Enhanced method with sort method parameter
    static func fetchMoodPosts(
        skip: Int = 0,
        limit: Int = 20,
        sort: FeedSortMethod = .relevance, // Default to relevance
        completion: @escaping (Result<(posts: [MoodPost], pagination: PaginationMetadata?), MoodPostServiceError>) -> Void
    ) {
        guard var components = URLComponents(url: Config.apiURL(for: "/api/feed"), resolvingAgainstBaseURL: false) else {
            completion(.failure(.invalidURL))
            return
        }
        
        components.queryItems = [
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("MoodPostService: Fetching \(sort.displayName) feed from \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("MoodPostService: Network error - \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("MoodPostService: Invalid response object.")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("MoodPostService: Received HTTP status \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = httpResponse.statusCode
                    var message = "Server error with status code \(statusCode)."
                    if let data = data, let serverMsg = String(data: data, encoding: .utf8), !serverMsg.isEmpty {
                        message = serverMsg
                    }
                    completion(.failure(.serverError(statusCode: statusCode, message: message)))
                    return
                }
                
                guard let data = data else {
                    print("MoodPostService: No data received.")
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let moodPostsArray = try JSONDecoder().decode([MoodPost].self, from: data)
                    completion(.success((posts: moodPostsArray, pagination: nil)))
                } catch let decodingError {
                    print("MoodPostService: JSON decoding error - \(decodingError.localizedDescription)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("MoodPostService: Raw response: \(responseString)")
                    }
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
    
    // Backward compatibility method
    static func fetchMoodPosts(
        skip: Int = 0,
        limit: Int = 20,
        sort: String = "relevance",
        completion: @escaping (Result<(posts: [MoodPost], pagination: PaginationMetadata?), MoodPostServiceError>) -> Void
    ) {
        let sortMethod = FeedSortMethod(rawValue: sort) ?? .relevance
        fetchMoodPosts(skip: skip, limit: limit, sort: sortMethod, completion: completion)
    }
    
    // Existing method for specific endpoints (profile posts, etc.)
    static func fetchMoodPosts(
        endpoint: String,
        skip: Int? = nil,
        limit: Int? = nil,
        completion: @escaping (Result<(posts: [MoodPost], pagination: PaginationMetadata?), MoodPostServiceError>) -> Void
    ) {
        guard var urlComponents = URLComponents(url: Config.apiURL(for: endpoint), resolvingAgainstBaseURL: false) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var queryItems: [URLQueryItem] = []
        if let skipVal = skip, let limitVal = limit, limitVal > 0 {
            queryItems.append(URLQueryItem(name: "page", value: String((skipVal / limitVal) + 1)))
            queryItems.append(URLQueryItem(name: "limit", value: String(limitVal)))
        } else if let limitVal = limit {
            queryItems.append(URLQueryItem(name: "page", value: "1"))
            queryItems.append(URLQueryItem(name: "limit", value: String(limitVal)))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
        }
        
        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("MoodPostService (endpoint: \(endpoint)): Fetching posts from \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("MoodPostService (endpoint: \(endpoint)): Network error - \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("MoodPostService (endpoint: \(endpoint)): Invalid response.")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("MoodPostService (endpoint: \(endpoint)): Status \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = httpResponse.statusCode
                    var message = "Server error with status code \(statusCode)."
                    if let data = data, let serverMsg = String(data: data, encoding: .utf8), !serverMsg.isEmpty {
                        message = serverMsg
                    }
                    completion(.failure(.serverError(statusCode: statusCode, message: message)))
                    return
                }
                
                guard let data = data else {
                    print("MoodPostService (endpoint: \(endpoint)): No data received.")
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let paginatedResponse = try JSONDecoder().decode(UserCheckInsPaginatedResponse.self, from: data)
                    let metadata = PaginationMetadata(
                        currentPage: paginatedResponse.currentPage,
                        totalPages: paginatedResponse.totalPages,
                        totalCount: paginatedResponse.totalCount
                    )
                    completion(.success((posts: paginatedResponse.data, pagination: metadata)))
                } catch let decodingError {
                    print("MoodPostService (endpoint: \(endpoint)): Decoding error - \(decodingError.localizedDescription)")
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
}
