import Foundation
import SwiftUI

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

struct UpdatePreferencesRequest: Codable {
    let pushNotificationsEnabled: Bool
    let notificationHourPST: Int
    let notificationMinutePST: Int
}


// MARK: - Errors
enum AuthenticationError: LocalizedError {
    case invalidURL(String)
    case networkError(Error, URL?)
    case invalidResponse(URL?)
    case noData(URL?)
    case decodingError(Error, URL?)
    case serverError(statusCode: Int, message: String, URL?)
    case weakPassword
    case emailOrUsernameTaken
    case invalidCredentials
    case registrationFailed(details: String)
    case sessionExpired
    case underlying(Error)
    
    var errorDescription: String? {
        switch self {
            case .invalidURL(let url): return "Invalid server URL: \(url)"
            case .networkError(let error, let url): return "Network error for \(url?.absoluteString ?? "N/A"): \(error.localizedDescription)"
            case .invalidResponse(let url): return "Invalid response from server for \(url?.absoluteString ?? "N/A")"
            case .noData(let url): return "No data received from server for \(url?.absoluteString ?? "N/A")"
            case .decodingError(let error, let url): return "Failed to process server response for \(url?.absoluteString ?? "N/A"): \(error.localizedDescription)"
            case .serverError(_, let message, _): return message
            case .weakPassword: return "Password must be at least 10 characters with uppercase, lowercase, number, and special character."
            case .emailOrUsernameTaken: return "Email or username is already taken."
            case .invalidCredentials: return "Invalid email or password."
            case .registrationFailed(let details): return "Registration failed: \(details)"
            case .sessionExpired: return "Your session has expired. Please log in again."
            case .underlying(let error): return error.localizedDescription
        }
    }
}

// MARK: - HTTP Method Enum
private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

// MARK: - Authentication Service
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var currentUser: User? {
        didSet {
            print("[AuthService][StateChange] currentUser updated: \(currentUser?.username ?? "nil")")
        }
    }
    
    private var accessToken: String? {
        didSet {
            DispatchQueue.main.async {
                let newAuthStatus = self.accessToken != nil
                if self.isAuthenticated != newAuthStatus {
                    self.isAuthenticated = newAuthStatus
                    print("[AuthService][StateChange] isAuthenticated changed to: \(self.isAuthenticated)")
                }
            }
            if let token = accessToken {
                KeychainManager.shared.saveTokens(access: token, refresh: refreshToken ?? "")
            }
        }
    }
    private var refreshToken: String? {
        didSet {
            if let access = accessToken, let refresh = refreshToken {
                KeychainManager.shared.saveTokens(access: access, refresh: refresh)
            }
        }
    }
    
    private let jsonDecoder: JSONDecoder // Centralized decoder
    
    private init() {
        self.jsonDecoder = JSONDecoder()
        // Attempt to support multiple common date formats from backend
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        self.jsonDecoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ", // Standard ISO8601 with milliseconds
                "yyyy-MM-dd'T'HH:mm:ssZ",    // ISO8601 without milliseconds
            ]
            
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        print("[AuthService][Init] Initializing and loading stored tokens.")
        loadStoredTokens()
    }
    
    // MARK: - Private Network Helper
    private func performRequest(
        endpoint: String,
        method: HTTPMethod,
        body: (any Codable)? = nil,
        requiresAuth: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let url = Config.apiURL(for: endpoint)
        print("[AuthService][Network] Attempting \(method.rawValue) request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            guard let token = self.accessToken else {
                print("[AuthService][Network] Error: Auth required but no access token found for \(url.absoluteString).")
                throw AuthenticationError.sessionExpired
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                print("[AuthService][Network] Error: Failed to encode request body for \(url.absoluteString): \(error)")
                throw AuthenticationError.decodingError(error, url)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[AuthService][Network] Error: Invalid response (not HTTPURLResponse) for \(url.absoluteString).")
                throw AuthenticationError.invalidResponse(url)
            }
            print("[AuthService][Network] \(method.rawValue) to \(url.absoluteString) completed with status: \(httpResponse.statusCode)")
            return (data, httpResponse)
        } catch {
            print("[AuthService][Network] Error: URLSession request failed for \(url.absoluteString): \(error)")
            throw AuthenticationError.networkError(error, url)
        }
    }
    
    func updateUserPreferences(
            pushEnabled: Bool,
            notificationHourPST: Int,
            notificationMinutePST: Int
            // Add other preference parameters here if your backend expects them
            // shareLocation: Bool? = nil,
            // showMoodToStrangers: Bool? = nil,
            // anonymousSharing: Bool? = nil
        ) async throws {
            guard isAuthenticated, let userId = self.currentUserId else {
                print("[AuthService][Preferences] User not authenticated or no user ID. Cannot update preferences.")
                throw AuthenticationError.sessionExpired
            }

            print("[AuthService][Preferences] Attempting to update preferences for user: \(userId)")
            print("[AuthService][Preferences] Data to send: PushEnabled: \(pushEnabled), HourPST: \(notificationHourPST), MinutePST: \(notificationMinutePST)")

            let requestBody = UpdatePreferencesRequest(
                pushNotificationsEnabled: pushEnabled,
                notificationHourPST: notificationHourPST,
                notificationMinutePST: notificationMinutePST
                // Map other parameters if you add them
            )

            do {
                // The endpoint path should match your backend route exactly (e.g., "/users/me/preferences")
                // It was previously "/api/users/me/preferences" in the backend example.
                // Ensure Config.apiURL(for: "/users/me/preferences") generates the correct full URL.
                let (data, httpResponse) = try await performRequest(
                    endpoint: "/auth/me/preferences", // Ensure this is the correct path
                    method: .put,
                    body: requestBody,
                    requiresAuth: true
                )

                if (200...299).contains(httpResponse.statusCode) {
                    print("[AuthService][Preferences] Successfully updated preferences on backend.")
                    // Optionally, decode response if backend sends back the updated user/preferences
                    // For now, we assume success means the backend updated it.

                    // IMPORTANT: Refresh local user data to reflect the changes
                    // This will also update UserDataProvider.shared.currentUser
                    // because UserDataProvider subscribes to AuthenticationService.shared.$currentUser
                    _ = try await fetchUserProfile() // Re-fetch profile to get the latest data
                    print("[AuthService][Preferences] User profile refreshed after preference update.")

                } else {
                    // Try to decode an error message from the backend
                    var errorMessage = "Failed to update preferences with status \(httpResponse.statusCode)."
                    if let errorData = try? jsonDecoder.decode(AuthErrorResponse.self, from: data) {
                        errorMessage = errorData.msg
                    } else if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                        errorMessage = responseString // Fallback to raw string if AuthErrorResponse fails
                    }
                    print("[AuthService][Preferences] Error updating preferences: \(errorMessage)")
                    throw AuthenticationError.serverError(statusCode: httpResponse.statusCode, message: errorMessage, httpResponse.url)
                }
            } catch let error as AuthenticationError {
                print("[AuthService][Preferences] AuthenticationError during preference update: \(error.localizedDescription)")
                throw error
            } catch {
                print("[AuthService][Preferences] Unexpected error during preference update: \(error.localizedDescription)")
                throw AuthenticationError.underlying(error)
            }
        }

    
    // MARK: - Public API
    func register(username: String, email: String, password: String) async throws -> RegisterResponse {
        print("[AuthService][Register] Attempting registration for username: \(username), email: \(email)")
        let requestBody = RegisterRequest(username: username, email: email, password: password)
        
        let (data, httpResponse) = try await performRequest(
            endpoint: "/auth/register",
            method: .post,
            body: requestBody,
            requiresAuth: false
        )
        
        switch httpResponse.statusCode {
            case 201:
                do {
                    let registerResponse = try jsonDecoder.decode(RegisterResponse.self, from: data)
                    print("[AuthService][Register] Success: \(registerResponse.username) registered.")
                    return registerResponse
                } catch {
                    print("[AuthService][Register] Error: Failed to decode successful registration response: \(error)")
                    throw AuthenticationError.decodingError(error, httpResponse.url)
                }
            case 400:
                let errorResponse = try? jsonDecoder.decode(AuthErrorResponse.self, from: data)
                let message = errorResponse?.msg ?? "Registration input error."
                print("[AuthService][Register] Error 400: \(message)")
                if message.lowercased().contains("weak password") { throw AuthenticationError.weakPassword }
                throw AuthenticationError.serverError(statusCode: 400, message: message, httpResponse.url)
            case 409:
                print("[AuthService][Register] Error 409: Email or username taken.")
                throw AuthenticationError.emailOrUsernameTaken
            default:
                let errorResponse = try? jsonDecoder.decode(AuthErrorResponse.self, from: data)
                let message = errorResponse?.msg ?? "Registration failed with status \(httpResponse.statusCode)."
                print("[AuthService][Register] Error \(httpResponse.statusCode): \(message)")
                throw AuthenticationError.serverError(statusCode: httpResponse.statusCode, message: message, httpResponse.url)
        }
    }
    
    func login(email: String, password: String) async throws -> LoginResponse {
        print("[AuthService][Login] Attempting login for email: \(email)")
        let requestBody = LoginRequest(email: email, password: password)
        
        let (data, httpResponse) = try await performRequest(
            endpoint: "/auth/login",
            method: .post,
            body: requestBody,
            requiresAuth: false
        )
        
        switch httpResponse.statusCode {
            case 200:
                do {
                    let loginResponse = try jsonDecoder.decode(LoginResponse.self, from: data)
                    print("[AuthService][Login] Token acquisition successful.")
                    
                    await MainActor.run {
                        self.accessToken = loginResponse.access
                        self.refreshToken = loginResponse.refresh
                        
                        if let userId = self.extractUserIdFromToken(loginResponse.access) {
                            self.currentUserId = userId
                            KeychainManager.shared.saveUserId(userId)
                            print("[AuthService][Login] UserID: \(userId) extracted and saved.")
                        }
                        
                        if self.accessToken != nil {
                            self.isAuthenticated = true
                            print("[AuthService][Login] isAuthenticated directly set to true on MainActor.")
                        } else {
                            self.isAuthenticated = false
                            print("[AuthService][Login] WARNING: accessToken was nil after decoding loginResponse. isAuthenticated set to false.")
                        }
                    }
                    return loginResponse
                } catch {
                    print("[AuthService][Login] Error: Failed to decode successful login response: \(error)")
                    await MainActor.run { self.isAuthenticated = false }
                    throw AuthenticationError.decodingError(error, httpResponse.url)
                }
            case 401:
                print("[AuthService][Login] Error 401: Invalid credentials.")
                await MainActor.run { self.isAuthenticated = false }
                throw AuthenticationError.invalidCredentials
            default:
                let errorResponse = try? jsonDecoder.decode(AuthErrorResponse.self, from: data)
                let message = errorResponse?.msg ?? "Login failed with status \(httpResponse.statusCode)."
                print("[AuthService][Login] Error \(httpResponse.statusCode): \(message)")
                await MainActor.run { self.isAuthenticated = false }
                throw AuthenticationError.serverError(statusCode: httpResponse.statusCode, message: message, httpResponse.url)
        }
    }
    
    func loginAndFetchProfile(email: String, password: String) async throws {
        print("[AuthService][LoginFlow] Initiating login and profile fetch for email: \(email)")
        _ = try await login(email: email, password: password) // login() already handles setting isAuthenticated

        if self.isAuthenticated {
            print("[AuthService][LoginFlow] Login successful (isAuthenticated is true), proceeding to fetch profile and send pending FCM token.")
            // Send any pending FCM token now that user is authenticated
            sendPendingFCMTokenIfNeeded()
            
            do {
                _ = try await fetchUserProfile()
                print("[AuthService][LoginFlow] loginAndFetchProfile: Profile fetch returned. CurrentUser in AuthSvc: \(self.currentUser?.username ?? "nil")")
            } catch {
                print("[AuthService][LoginFlow] ERROR: fetchUserProfile failed AFTER successful login token acquisition: \(error.localizedDescription)")
                // Don't re-throw here if you want to allow login to "succeed" even if profile fetch fails initially
                // but do log it. The UI should handle a nil currentUser.
            }
        } else {
            print("[AuthService][LoginFlow] CRITICAL Error: Login attempt finished, but user is NOT authenticated before profile fetch. This indicates an issue in login() state update logic if login didn't throw.")
            // This case should ideally not be hit if login() correctly updates isAuthenticated and throws on failure.
            throw AuthenticationError.underlying(NSError(domain: "AuthFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Internal authentication flow error: isAuthenticated was false after login() completed without error."]))
        }
    }
    
    func logout() {
        print("[AuthService][Logout] Logging out user.")
        DispatchQueue.main.async {
            self.accessToken = nil
            self.refreshToken = nil
            self.currentUserId = nil
            self.currentUser = nil
        }
        KeychainManager.shared.clearTokens()
        print("[AuthService][Logout] Session cleared from memory and Keychain.")
    }
    
    func fetchUserProfile() async throws -> User {
        guard self.isAuthenticated, let userId = self.currentUserId else {
            print("[AuthService][ProfileFetch] Pre-check failed: Not authenticated or no user ID. IsAuth: \(isAuthenticated), UserID: \(self.currentUserId ?? "nil"). currentUser will not be set.") // CLARIFY
            throw AuthenticationError.sessionExpired
        }
        print("[AuthService][ProfileFetch] Attempting for user ID: \(userId). Current self.currentUser before fetch: \(self.currentUser?.username ?? "nil")")
        
        let (data, httpResponse) = try await performRequest(endpoint: "/auth/profile", method: .get, requiresAuth: true)
        
        switch httpResponse.statusCode {
            case 200:
                do {
                    let user = try jsonDecoder.decode(User.self, from: data)
                    print("[AuthService][ProfileFetch] Success: SUCCESSFULLY DECODED User object. Username: \(user.username), Email: \(user.email), ID: \(user.id)")
                    
                    await MainActor.run {
                        print("[AuthService][ProfileFetch] PRE-ASSIGN on MainActor. Current self.currentUser?.username: \(self.currentUser?.username ?? "nil")")
                        self.currentUser = user
                        print("[AuthService][ProfileFetch] POST-ASSIGN on MainActor. New self.currentUser?.username: \(self.currentUser?.username ?? "nil")")
                    }
                    saveUserToKeychain(user)
                    //printUserObjectDetails(user, context: "ProfileFetch SUCCESS")
                    return user
                } catch {
                    print("[AuthService][ProfileFetch] Error: Failed to decode successful profile response (HTTP 200). This is a CRITICAL error if data was expected.")
                    if let decodingError = error as? DecodingError { printDecodingErrorDetails(decodingError) }
                    throw AuthenticationError.decodingError(error, httpResponse.url)
                }
            default:
                let errorResponse = try? jsonDecoder.decode(AuthErrorResponse.self, from: data)
                let message = errorResponse?.msg ?? "Failed to fetch profile with status \(httpResponse.statusCode)."
                print("[AuthService][ProfileFetch] Error \(httpResponse.statusCode): \(message)")
                throw AuthenticationError.serverError(statusCode: httpResponse.statusCode, message: message, httpResponse.url)
        }
    }
        
    func refreshAccessToken() async {
        guard let currentRefreshToken = self.refreshToken else {
            print("[AuthService][TokenRefresh] No refresh token available. Cannot refresh.")
            await MainActor.run { self.logout() }
            return
        }
        print("[AuthService][TokenRefresh] Attempting token refresh.")
        
        do {
            let url = Config.apiURL(for: "/auth/refresh")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(currentRefreshToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[AuthService][TokenRefresh] Error: Invalid response type (not HTTPURLResponse). Logging out.")
                await MainActor.run { self.logout() }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("[AuthService][TokenRefresh] Error: Refresh request failed with status \(httpResponse.statusCode). Logging out.")
                await MainActor.run { self.logout() }
                return
            }
            
            let newTokens = try jsonDecoder.decode(LoginResponse.self, from: data)
            print("[AuthService][TokenRefresh] Success: Tokens refreshed.")
            await MainActor.run {
                self.accessToken = newTokens.access
                self.refreshToken = newTokens.refresh
                if let userId = self.extractUserIdFromToken(newTokens.access) {
                    self.currentUserId = userId
                    KeychainManager.shared.saveUserId(userId)
                }
            }
            print("[AuthService][TokenRefresh] Fetching profile after successful token refresh.")
            _ = try await fetchUserProfile()
            
        } catch {
            print("[AuthService][TokenRefresh] Error: Exception during token refresh: \(error.localizedDescription). Logging out.")
            await MainActor.run { self.logout() }
        }
    }
    
    // MARK: - Token Utilities & Persistence
    func getAccessToken() -> String? {
        return accessToken
    }
    
    private func loadStoredTokens() {
        let (access, refresh) = KeychainManager.shared.retrieveTokens()
        print("[AuthService][InitLoad] Retrieved from Keychain: access token \(access != nil ? "found" : "NOT found"), refresh token \(refresh != nil ? "found" : "NOT found").")
        
        guard let loadedAccessToken = access, let loadedRefreshToken = refresh else {
            print("[AuthService][InitLoad] No complete token pair in Keychain. CurrentUser will remain nil.")
            Task {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.currentUserId = nil
                }
            }
            return
        }
        
        if !isTokenExpired(loadedAccessToken) {
            print("[AuthService][InitLoad] Access token is valid.")
            Task {
                await MainActor.run {
                    self.accessToken = loadedAccessToken
                    self.refreshToken = loadedRefreshToken
                    if let userId = KeychainManager.shared.retrieveUserId() ?? self.extractUserIdFromToken(loadedAccessToken) {
                        self.currentUserId = userId
                        KeychainManager.shared.saveUserId(userId)
                        print("[AuthService][InitLoad] UserID set to: \(userId).")
                    }
                    self.isAuthenticated = true
                    print("[AuthService][InitLoad] isAuthenticated set to true. UserID: \(self.currentUserId ?? "nil")")
                }
                if self.isAuthenticated && self.currentUserId != nil {
                    print("[AuthService][InitLoad] Conditions MET to fetch profile. IsAuth: \(self.isAuthenticated), UserID: \(self.currentUserId!).")
                    do {
                        print("[AuthService][InitLoad] Attempting to call fetchUserProfile().")
                        _ = try await self.fetchUserProfile()
                        print("[AuthService][InitLoad] fetchUserProfile() call completed. Check subsequent logs for currentUser content.")
                    } catch {
                        print("[AuthService][InitLoad] Error calling fetchUserProfile() from loadStoredTokens: \(error.localizedDescription)")
                        await MainActor.run { self.logout() }
                    }
                } else {
                    print("[AuthService][InitLoad] Conditions NOT MET to fetch profile. IsAuth: \(self.isAuthenticated), UserID: \(self.currentUserId ?? "nil"). currentUser will remain nil from this path.")
                    // Ensure currentUser is nil if profile isn't fetched
                    await MainActor.run {
                        if self.currentUser != nil {
                            self.currentUser = nil
                            print("[AuthService][InitLoad] currentUser explicitly set to nil as profile fetch was skipped.")
                        }
                    }
                }
            }
        } else {
            print("[AuthService][InitLoad] Access token expired. Attempting refresh.")
            Task {
                await self.refreshAccessToken()
            }
        }
    }
    
    private func isTokenExpired(_ token: String) -> Bool {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3,
              let payloadData = base64URLDecode(segments[1]),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? Double else {
            print("[AuthService][TokenUtil] Failed to parse token for expiration check.")
            return true // Treat as expired if unparseable
        }
        let expirationDate = Date(timeIntervalSince1970: exp)
        let isExpired = Date() >= expirationDate
        print("[AuthService][TokenUtil] Token expiration check: \(isExpired ? "EXPIRED" : "VALID"). Expires at: \(expirationDate)")
        return isExpired
    }
    
    private func extractUserIdFromToken(_ token: String) -> String? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3,
              let payloadData = base64URLDecode(segments[1]),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let userId = payload["sub"] as? String else {
            print("[AuthService][TokenUtil] Failed to extract UserID (sub claim) from token.")
            return nil
        }
        return userId
    }
    
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 { base64 += String(repeating: "=", count: 4 - base64.count % 4) }
        return Data(base64Encoded: base64)
    }
    
    // MARK: - Keychain User Profile
    private func saveUserToKeychain(_ user: User) {
        print("[AuthService][Keychain] Attempting to save user profile to Keychain for user: \(user.username)")
        do {
            let userData = try JSONEncoder().encode(user)
            if let userString = String(data: userData, encoding: .utf8) {
                try KeychainManager.shared.save(userString, for: "com.uclamoods.currentUser")
                print("[AuthService][Keychain] User profile saved successfully.")
            } else {
                print("[AuthService][Keychain] Error: Could not convert user data to string for Keychain saving.")
            }
        } catch {
            print("[AuthService][Keychain] Error: Failed to encode or save user profile to Keychain: \(error)")
        }
    }
    
    func loadStoredUser() -> User? {
        print("[AuthService][Keychain] Attempting to load stored user profile from Keychain.")
        guard let userString = try? KeychainManager.shared.retrieve(for: "com.uclamoods.currentUser"),
              let userData = userString.data(using: .utf8) else {
            print("[AuthService][Keychain] No stored user profile string found or failed to convert to data.")
            return nil
        }
        do {
            let user = try jsonDecoder.decode(User.self, from: userData)
            print("[AuthService][Keychain] Successfully loaded and decoded stored user: \(user.username)")
            return user
        } catch {
            print("[AuthService][Keychain] Error: Failed to decode stored user profile: \(error)")
            if let decodingError = error as? DecodingError { printDecodingErrorDetails(decodingError) }
            return nil
        }
    }
    
    // MARK: - App Status Checks
    func checkAuthenticationStatus() {
        print("[AuthService][StatusCheck] Explicitly checking authentication status.")
        loadStoredTokens()
    }
    
    // MARK: - Email Validation
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func sendFCMTokenToBackend(fcmToken: String) {
            // Only send if the user is authenticated and we have a user ID
            guard isAuthenticated, let userId = self.currentUserId else {
                print("[AuthService][FCM] User not authenticated or no user ID. FCM token not sent yet. Token: \(fcmToken)")
                // You might want to store the token locally and send it once the user logs in.
                UserDefaults.standard.set(fcmToken, forKey: "pendingFCMToken")
                return
            }
            
            // Clear any pending token if we are about to send one
            UserDefaults.standard.removeObject(forKey: "pendingFCMToken")

            print("[AuthService][FCM] Attempting to send FCM token to backend for user: \(userId). Token: \(fcmToken)")

            Task {
                do {
                    let requestBody = ["fcmToken": fcmToken]
                    // Assuming your endpoint is /api/users/me/fcm-token as discussed
                    // and it's a PUT request.
                    let (data, httpResponse) = try await performRequest(
                        endpoint: "/auth/me/fcm-token", // Make sure this path matches your Express route EXACTLY
                        method: .put,
                        body: requestBody,
                        requiresAuth: true
                    )

                    if (200...299).contains(httpResponse.statusCode) {
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("[AuthService][FCM] Successfully sent FCM token to backend. Response: \(responseString)")
                        } else {
                            print("[AuthService][FCM] Successfully sent FCM token to backend (no response body).")
                        }
                        // You could store a flag indicating the token was successfully sent
                        // UserDefaults.standard.set(fcmToken, forKey: "lastSentFCMToken")
                    } else {
                        let errorResponse = try? jsonDecoder.decode(AuthErrorResponse.self, from: data)
                        let message = errorResponse?.msg ?? "Failed to send FCM token with status \(httpResponse.statusCode)."
                        print("[AuthService][FCM] Error sending FCM token: \(message)")
                        // Store the token to retry later if it failed
                        UserDefaults.standard.set(fcmToken, forKey: "pendingFCMToken")
                    }
                } catch {
                    print("[AuthService][FCM] Network or other error sending FCM token: \(error.localizedDescription)")
                    // Store the token to retry later
                    UserDefaults.standard.set(fcmToken, forKey: "pendingFCMToken")
                }
            }
        }

        // Call this after successful login or when app foregrounds if a token is pending
        func sendPendingFCMTokenIfNeeded() {
            if let pendingToken = UserDefaults.standard.string(forKey: "pendingFCMToken") {
                print("[AuthService][FCM] Found pending FCM token. Attempting to send.")
                sendFCMTokenToBackend(fcmToken: pendingToken)
            }
        }



    
    // MARK: - Debug Helpers
//    private func printUserObjectDetails(_ user: User, context: String) {
//        print("""
//        [AuthService][\(context)] User Object Details:
//          ID: \(user.id)
//          Username: \(user.username)
//          Email: \(user.email)
//          Profile Picture: \(user.profilePicture ?? "N/A")
//          IsActive: \(user.isActive.description ?? "N/A")
//          Last Login: \(user.lastLogin?.description ?? "N/A")
//          Created At: \(user.createdAt?.description ?? "N/A")
//          Updated At: \(user.updatedAt?.description ?? "N/A")
//          Preferences:
//            Push Enabled: \(user.preferences?.pushNotificationsEnabled?.description ?? "N/A")
//            Share Location: \(user.preferences?.shareLocationForHeatmap?.description ?? "N/A")
//            Show Mood to Strangers: \(user.preferences?.privacySettings?.showMoodToStrangers?.description ?? "N/A")
//            Anonymous Sharing: \(user.preferences?.privacySettings?.anonymousMoodSharing?.description ?? "N/A")
//            Notification Window: Start: \(user.preferences?.preferredNotificationTimeWindow?.start?.description ?? "N/A"), End: \(user.preferences?.preferredNotificationTimeWindow?.end?.description ?? "N/A")
//          Demographics:
//            Graduating Class: \(user.demographics?.graduatingClass?.description ?? "N/A")
//            Major: \(user.demographics?.major ?? "N/A")
//            Gender: \(user.demographics?.gender ?? "N/A")
//            Ethnicity: \(user.demographics?.ethnicity ?? "N/A")
//            Age: \(user.demographics?.age?.description ?? "N/A")
//        """)
//    }
    
    private func printDecodingErrorDetails(_ error: DecodingError) {
        var errorContext = "[AuthService][DecodingErrorDetails] "
        switch error {
            case .typeMismatch(let type, let context):
                errorContext += "Type mismatch for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
            case .valueNotFound(let type, let context):
                errorContext += "Value not found for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
            case .keyNotFound(let key, let context):
                errorContext += "Key not found: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
            case .dataCorrupted(let context):
                errorContext += "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
            @unknown default:
                errorContext += "Unknown decoding error: \(error.localizedDescription)"
        }
        print(errorContext)
    }
}

// MARK: - URLRequest Extension
extension URLRequest {
    mutating func addAuthenticationIfNeeded() {
        if let token = AuthenticationService.shared.getAccessToken() {
            self.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
