import Foundation
import SwiftUI

// MARK: - Models
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct RegisterResponse: Codable {
    let id: String
    let username: String
    let email: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let access: String
    let refresh: String
}

struct AuthErrorResponse: Codable {
    let msg: String
    let details: String?
}

// MARK: - Errors
enum AuthenticationError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
    case weakPassword
    case emailOrUsernameTaken
    case invalidCredentials
    case registrationFailed(details: String)
    
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
            return message
        case .weakPassword:
            return "Password must be at least 10 characters with uppercase, lowercase, number, and special character"
        case .emailOrUsernameTaken:
            return "Email or username is already taken"
        case .invalidCredentials:
            return "Invalid email or password"
        case .registrationFailed(let details):
            return "Registration failed: \(details)"
        }
    }
}

// MARK: - Authentication Service
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    
    private var accessToken: String? {
        didSet {
            DispatchQueue.main.async {
                self.isAuthenticated = self.accessToken != nil
            }
            // Save to keychain when set
            if let token = accessToken {
                KeychainManager.shared.saveTokens(
                    access: token,
                    refresh: refreshToken ?? ""
                )
            }
        }
    }
    private var refreshToken: String? {
        didSet {
            // Save to keychain when set
            if let access = accessToken, let refresh = refreshToken {
                KeychainManager.shared.saveTokens(
                    access: access,
                    refresh: refresh
                )
            }
        }
    }
    
    private init() {
        // Load tokens from keychain on init
        loadStoredTokens()
    }
    
    // MARK: - Register
    func register(username: String, email: String, password: String) async throws -> RegisterResponse {
        let endpoint = "/auth/register"
        let url = Config.apiURL(for: endpoint)
        
        let request = RegisterRequest(username: username, email: email, password: password)
        guard let encodedData = try? JSONEncoder().encode(request) else {
            throw AuthenticationError.decodingError(NSError(domain: "EncodingError", code: 0, userInfo: nil))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = encodedData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthenticationError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 201:
                let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                return registerResponse
                
            case 400:
                let errorResponse = try JSONDecoder().decode(AuthErrorResponse.self, from: data)
                if errorResponse.msg == "Weak password" {
                    throw AuthenticationError.weakPassword
                }
                throw AuthenticationError.serverError(statusCode: 400, message: errorResponse.msg)
                
            case 409:
                throw AuthenticationError.emailOrUsernameTaken
                
            case 500:
                let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
                throw AuthenticationError.registrationFailed(details: errorResponse?.details ?? "Unknown error")
                
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthenticationError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch {
            if error is AuthenticationError {
                throw error
            }
            throw AuthenticationError.networkError(error)
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> LoginResponse {
        let endpoint = "/auth/login"
        let url = Config.apiURL(for: endpoint)
        
        let request = LoginRequest(email: email, password: password)
        guard let encodedData = try? JSONEncoder().encode(request) else {
            throw AuthenticationError.decodingError(NSError(domain: "EncodingError", code: 0, userInfo: nil))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = encodedData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthenticationError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                // Store tokens
                self.accessToken = loginResponse.access
                self.refreshToken = loginResponse.refresh
                // Extract user ID from JWT if needed
                if let userId = self.extractUserIdFromToken(loginResponse.access) {
                    self.currentUserId = userId
                    KeychainManager.shared.saveUserId(userId)
                }
                return loginResponse
                
            case 401:
                throw AuthenticationError.invalidCredentials
                
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthenticationError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch {
            if error is AuthenticationError {
                throw error
            }
            throw AuthenticationError.networkError(error)
        }
    }
    
    // MARK: - Logout
    func logout() {
        DispatchQueue.main.async {
            self.accessToken = nil
            self.refreshToken = nil
            self.currentUserId = nil
            self.isAuthenticated = false
        }
        // Clear from keychain
        KeychainManager.shared.clearTokens()
    }
    
    // MARK: - Token Management
    func getAccessToken() -> String? {
        return accessToken
    }
    
    // MARK: - Token Persistence
    private func loadStoredTokens() {
        let (access, refresh) = KeychainManager.shared.retrieveTokens()
        if let access = access, let refresh = refresh {
            // Validate token isn't expired before using
            if !isTokenExpired(access) {
                DispatchQueue.main.async {
                    self.accessToken = access
                    self.refreshToken = refresh
                    
                    // Load user ID
                    if let userId = KeychainManager.shared.retrieveUserId() {
                        self.currentUserId = userId
                    } else if let userId = self.extractUserIdFromToken(access) {
                        self.currentUserId = userId
                        KeychainManager.shared.saveUserId(userId)
                    }
                    
                    self.isAuthenticated = true
                }
            } else {
                // Token expired, try to refresh
                Task {
                    await refreshAccessToken()
                }
            }
        }
    }
    
    // MARK: - Token Validation & Refresh
    private func isTokenExpired(_ token: String) -> Bool {
        // Basic JWT expiration check
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else { return true }
        
        let payloadSegment = segments[1]
        guard let payloadData = base64URLDecode(payloadSegment),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? Double else {
            return true
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        return Date() >= expirationDate
    }
    
    private func extractUserIdFromToken(_ token: String) -> String? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else { return nil }
        
        let payloadSegment = segments[1]
        guard let payloadData = base64URLDecode(payloadSegment),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let userId = payload["sub"] as? String else {
            return nil
        }
        
        return userId
    }
    
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
    
    // MARK: - Token Refresh
    func refreshAccessToken() async {
        guard let refreshToken = self.refreshToken else { return }
        
        // TODO: Implement refresh token endpoint call
        // For now, we'll just clear the tokens if refresh fails
        // You'll need to add a refresh endpoint to your backend
        
        let endpoint = "/auth/refresh"
        let url = Config.apiURL(for: endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Refresh failed, clear tokens and redirect to login
                await MainActor.run {
                    self.logout()
                }
                return
            }
            
            let newTokens = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            await MainActor.run {
                self.accessToken = newTokens.access
                self.refreshToken = newTokens.refresh
            }
        } catch {
            // Refresh failed, clear tokens and redirect to login
            await MainActor.run {
                self.logout()
            }
        }
    }
    
    // Check if user is logged in on app launch
    func checkAuthenticationStatus() {
        // This is now handled by loadStoredTokens() in init
        // But you can call this to re-check if needed
        loadStoredTokens()
    }
    
    // Helper method to validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
}

// MARK: - URLRequest Extension for Auth Headers
extension URLRequest {
    mutating func addAuthenticationIfNeeded() {
        if let token = AuthenticationService.shared.getAccessToken() {
            self.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
