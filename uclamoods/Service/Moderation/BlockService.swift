//
//  BlockService.swift
//  uclamoods
//
//  Created by Yang Gao on 6/4/25.
//
import SwiftUI

class BlockService {
    static func blockUser(userId: String, currentUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = "/api/users/\(userId)/block"
        let url = Config.apiURL(for: endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthenticationIfNeeded()
        
        let requestBody = ["userId": currentUserId]
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "BlockService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                completion(.failure(NSError(domain: "BlockService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            }
        }.resume()
    }
}


