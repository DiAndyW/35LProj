import SwiftUI

enum MoodPostServiceError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
}

class MoodPostService {
    private var posts: [MoodPost] = []
    
    static func fetchMoodPosts(endpoint: String, completion: @escaping (Result<[MoodPost], MoodPostServiceError>) -> Void) {
        let url = Config.apiURL(for: endpoint)
        
        print("MoodPostService: Fetching posts from \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("MoodPostService: Network request error - \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("MoodPostService: Invalid response object received.")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("MoodPostService: Received HTTP status code \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                var serverMessage: String? = "Unknown server error."
                if let responseData = data, let errorMessage = String(data: responseData, encoding: .utf8) {
                    serverMessage = errorMessage
                    print("MoodPostService: Server error message - \(errorMessage)")
                }
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: serverMessage)))
                return
            }
            
            guard let data = data else {
                print("MoodPostService: No data received from server.")
                completion(.failure(.noData))
                return
            }
            do {
                let decoder = JSONDecoder()
                let moodPosts = try decoder.decode([MoodPost].self, from: data)
                print("MoodPostService: Successfully decoded \(moodPosts.count) mood posts.")
                completion(.success(moodPosts))
            } catch let decodingError {
                print("MoodPostService: JSON decoding error - \(decodingError.localizedDescription)")
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
