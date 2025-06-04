//
//  BlockedUser.swift
//  uclamoods
//
//  Created by Yang Gao on 6/4/25.
//


import SwiftUI

struct BlockedUser: Codable, Identifiable {
    let id: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
    }
}

struct BlockedAccountsResponse: Codable {
    let blockedUsers: [BlockedUser]
    let count: Int
}

class BlockedAccountsService {
    static func fetchBlockedUsers(completion: @escaping (Result<[BlockedUser], Error>) -> Void) {
        let endpoint = "/api/users/me/blocked"
        let url = Config.apiURL(for: endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addAuthenticationIfNeeded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "BlockedAccountsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "BlockedAccountsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    do {
                        let response = try JSONDecoder().decode(BlockedAccountsResponse.self, from: data)
                        completion(.success(response.blockedUsers))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "BlockedAccountsService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            }
        }.resume()
    }
    
    static func unblockUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = "/api/users/\(userId)/unblock"
        let url = Config.apiURL(for: endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthenticationIfNeeded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "BlockedAccountsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                    completion(.failure(NSError(domain: "BlockedAccountsService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            }
        }.resume()
    }
}
