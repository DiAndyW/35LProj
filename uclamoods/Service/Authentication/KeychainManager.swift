//
//  KeychainManager.swift
//  uclamoods
//
//  Created by Yang Gao on 6/1/25.
//


import Foundation
import Security

// MARK: - Keychain Manager for Secure Token Storage
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let accessToken = "com.uclamoods.accessToken"
        static let refreshToken = "com.uclamoods.refreshToken"
        static let userId = "com.uclamoods.userId"
    }
    
    // MARK: - Error Handling
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }
    
    // MARK: - Save Methods
    func save(_ value: String, for key: String) throws {
        let data = value.data(using: .utf8)!
        
        // Check if item already exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.uclamoods"
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Item exists, update it
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else {
            // Item doesn't exist, add it
            var newItem = query
            newItem[kSecValueData as String] = data
            
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
        }
    }
    
    // MARK: - Retrieve Methods
    func retrieve(for key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.uclamoods",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let passwordData = item as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return password
    }
    
    // MARK: - Delete Methods
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.uclamoods"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Token Specific Methods
    func saveTokens(access: String, refresh: String) {
        do {
            try save(access, for: Keys.accessToken)
            try save(refresh, for: Keys.refreshToken)
        } catch {
            print("Error saving tokens to keychain: \(error)")
        }
    }
    
    func retrieveTokens() -> (access: String?, refresh: String?) {
        let access = try? retrieve(for: Keys.accessToken)
        let refresh = try? retrieve(for: Keys.refreshToken)
        return (access, refresh)
    }
    
    func clearTokens() {
        do {
            try delete(for: Keys.accessToken)
            try delete(for: Keys.refreshToken)
            try delete(for: Keys.userId)
        } catch {
            print("Error clearing tokens from keychain: \(error)")
        }
    }
    
    func saveUserId(_ userId: String) {
        do {
            try save(userId, for: Keys.userId)
        } catch {
            print("Error saving user ID to keychain: \(error)")
        }
    }
    
    func retrieveUserId() -> String? {
        return try? retrieve(for: Keys.userId)
    }
}