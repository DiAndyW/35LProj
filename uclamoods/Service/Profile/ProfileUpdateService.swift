//
//  ProfileUpdateService.swift
//  uclamoods
//
//  Created by Assistant on 6/4/25.
//

import Foundation

// MARK: - Request/Response Models
struct ChangeUsernameRequest: Codable {
    let newUsername: String
    let currentPassword: String
}

struct ChangeUsernameResponse: Codable {
    let msg: String
    let username: String
}

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

struct ChangePasswordResponse: Codable {
    let msg: String
}

struct DeleteAccountResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Profile Update Errors
enum ProfileUpdateError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case encodingFailed
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message ?? "Server error occurred"
        case .encodingFailed:
            return "Failed to prepare request data"
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        }
    }
}

// MARK: - Profile Update Service
class ProfileUpdateService {
    
    // MARK: - Change Username
    static func changeUsername(newUsername: String, currentPassword: String) async throws {
        guard AuthenticationService.shared.isAuthenticated else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        let url = Config.apiURL(for: "/auth/me/username")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthenticationIfNeeded()
        
        let requestBody = ChangeUsernameRequest(
            newUsername: newUsername,
            currentPassword: currentPassword
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("[ProfileUpdateService]: Failed to encode username change request - \(error)")
            throw ProfileUpdateError.encodingFailed
        }
        
        print("[ProfileUpdateService]: Changing username to '\(newUsername)'")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ProfileUpdateService]: Invalid response type for username change")
                throw ProfileUpdateError.invalidResponse
            }
            
            print("[ProfileUpdateService]: Username change response status: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let changeResponse = try JSONDecoder().decode(ChangeUsernameResponse.self, from: data)
                    print("[ProfileUpdateService]: Username changed successfully to '\(changeResponse.username)'")
                } catch {
                    print("[ProfileUpdateService]: Failed to decode username change response - \(error)")
                    // Still consider it successful if we got 200-level status
                }
            } else {
                var errorMessage = "Failed to change username"
                
                // Try to decode error response
                if let errorData = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                    errorMessage = errorData.msg
                } else if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    errorMessage = responseString
                }
                
                print("[ProfileUpdateService]: Username change error (\(httpResponse.statusCode)): \(errorMessage)")
                throw ProfileUpdateError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
        } catch let error as ProfileUpdateError {
            throw error
        } catch {
            print("[ProfileUpdateService]: Network error during username change - \(error)")
            throw ProfileUpdateError.networkError(error)
        }
    }
    
    // MARK: - Delete Account
    static func deleteAccount() async throws {
        guard AuthenticationService.shared.isAuthenticated else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        let url = Config.apiURL(for: "/auth/delete-account")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthenticationIfNeeded()
        
        print("[ProfileUpdateService]: Deleting account")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ProfileUpdateService]: Invalid response type for account deletion")
                throw ProfileUpdateError.invalidResponse
            }
            
            print("[ProfileUpdateService]: Account deletion response status: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let deleteResponse = try JSONDecoder().decode(DeleteAccountResponse.self, from: data)
                    print("[ProfileUpdateService]: Account deleted successfully - \(deleteResponse.message)")
                } catch {
                    print("[ProfileUpdateService]: Failed to decode account deletion response - \(error)")
                    // Still consider it successful if we got 200-level status
                    print("[ProfileUpdateService]: Account deletion completed (couldn't decode response but got success status)")
                }
            } else {
                var errorMessage = "Failed to delete account"
                
                // Try to decode error response
                if let errorData = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                    errorMessage = errorData.msg
                } else if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    errorMessage = responseString
                }
                
                print("[ProfileUpdateService]: Account deletion error (\(httpResponse.statusCode)): \(errorMessage)")
                throw ProfileUpdateError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
        } catch let error as ProfileUpdateError {
            throw error
        } catch {
            print("[ProfileUpdateService]: Network error during account deletion - \(error)")
            throw ProfileUpdateError.networkError(error)
        }
    }
    
    // MARK: - Change Password
    static func changePassword(currentPassword: String, newPassword: String) async throws {
        guard AuthenticationService.shared.isAuthenticated else {
            throw ProfileUpdateError.notAuthenticated
        }
        
        let url = Config.apiURL(for: "/auth/me/password")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthenticationIfNeeded()
        
        let requestBody = ChangePasswordRequest(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("[ProfileUpdateService]: Failed to encode password change request - \(error)")
            throw ProfileUpdateError.encodingFailed
        }
        
        print("[ProfileUpdateService]: Changing password")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ProfileUpdateService]: Invalid response type for password change")
                throw ProfileUpdateError.invalidResponse
            }
            
            print("[ProfileUpdateService]: Password change response status: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let changeResponse = try JSONDecoder().decode(ChangePasswordResponse.self, from: data)
                    print("[ProfileUpdateService]: Password changed successfully - \(changeResponse.msg)")
                } catch {
                    print("[ProfileUpdateService]: Failed to decode password change response - \(error)")
                    // Still consider it successful if we got 200-level status
                }
            } else {
                var errorMessage = "Failed to change password"
                
                // Try to decode error response
                if let errorData = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                    errorMessage = errorData.msg
                } else if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    errorMessage = responseString
                }
                
                print("[ProfileUpdateService]: Password change error (\(httpResponse.statusCode)): \(errorMessage)")
                throw ProfileUpdateError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
        } catch let error as ProfileUpdateError {
            throw error
        } catch {
            print("[ProfileUpdateService]: Network error during password change - \(error)")
            throw ProfileUpdateError.networkError(error)
        }
    }
}
