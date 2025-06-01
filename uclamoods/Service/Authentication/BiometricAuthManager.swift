//
//  Keys.swift
//  uclamoods
//
//  Created by Yang Gao on 6/1/25.
//


import SwiftUI
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private init() {}
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your Morii account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        } else {
            completion(false, error)
        }
    }
    
    func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

// MARK: - User Defaults Keys
extension UserDefaults {
    private enum Keys {
        static let biometricAuthEnabled = "biometricAuthEnabled"
        static let lastAuthenticatedDate = "lastAuthenticatedDate"
    }
    
    var isBiometricAuthEnabled: Bool {
        get { bool(forKey: Keys.biometricAuthEnabled) }
        set { set(newValue, forKey: Keys.biometricAuthEnabled) }
    }
    
    var lastAuthenticatedDate: Date? {
        get { object(forKey: Keys.lastAuthenticatedDate) as? Date }
        set { set(newValue, forKey: Keys.lastAuthenticatedDate) }
    }
}

// MARK: - Security Settings View
struct SecuritySettingsView: View {
    @State private var isBiometricEnabled = UserDefaults.standard.isBiometricAuthEnabled
    @State private var showingBiometricAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Biometric Authentication Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Face ID / Touch ID")
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Use biometric authentication for quick access")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Toggle("", isOn: $isBiometricEnabled)
                    .labelsHidden()
                    .tint(.pink)
                    .onChange(of: isBiometricEnabled) { _, newValue in
                        handleBiometricToggle(newValue)
                    }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            // Session Management
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Security")
                    .font(.custom("Georgia", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                SettingsRow(
                    icon: "clock",
                    title: "Auto-logout",
                    subtitle: "After 30 days of inactivity"
                )
                
                SettingsRow(
                    icon: "iphone",
                    title: "Active Sessions",
                    subtitle: "Manage devices with access"
                ) {
                    // Show active sessions
                }
            }
        }
        .alert("Enable Biometric Authentication?", isPresented: $showingBiometricAlert) {
            Button("Cancel") {
                isBiometricEnabled = false
            }
            Button("Enable") {
                UserDefaults.standard.isBiometricAuthEnabled = true
            }
        } message: {
            Text("This will allow you to sign in using Face ID or Touch ID for faster access.")
        }
    }
    
    private func handleBiometricToggle(_ isEnabled: Bool) {
        if isEnabled {
            // Check if biometrics are available
            if BiometricAuthManager.shared.isBiometricsAvailable() {
                // Verify the user is authenticated before enabling
                if AuthenticationService.shared.isAuthenticated {
                    showingBiometricAlert = true
                } else {
                    isBiometricEnabled = false
                    // Show error that user needs to be logged in first
                }
            } else {
                isBiometricEnabled = false
                // Show error that biometrics aren't available
            }
        } else {
            UserDefaults.standard.isBiometricAuthEnabled = false
        }
    }
}

// MARK: - App Lock Screen (Optional)
struct AppLockView: View {
    @State private var isUnlocked = false
    let onUnlock: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                Text("Morii is Locked")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Authenticate to continue")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: authenticateWithBiometrics) {
                    HStack {
                        Image(systemName: "faceid")
                            .font(.system(size: 24))
                        Text("Unlock with Face ID")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.pink.opacity(0.8))
                    .cornerRadius(25)
                }
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        BiometricAuthManager.shared.authenticateWithBiometrics { success, error in
            if success {
                isUnlocked = true
                onUnlock()
            }
        }
    }
}
