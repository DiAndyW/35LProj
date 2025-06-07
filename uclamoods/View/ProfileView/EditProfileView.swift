//
//  EditProfileView.swift
//  uclamoods
//
//  Created by Assistant on 6/4/25.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var userDataProvider: UserDataProvider
    @StateObject private var authService = AuthenticationService.shared
    
    // Username change states
    @State private var newUsername: String = ""
    @State private var usernamePassword: String = ""
    @State private var isChangingUsername: Bool = false
    @State private var usernameSuccessMessage: String? = nil
    @State private var usernameErrorMessage: String? = nil
    
    // Password change states
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChangingPassword: Bool = false
    @State private var passwordSuccessMessage: String? = nil
    @State private var passwordErrorMessage: String? = nil
    
    // UI states
    @State private var showingUsernameSection: Bool = false
    @State private var showingPasswordSection: Bool = false
    
    // Delete account states
    @State private var showingDeleteConfirmation: Bool = false
    @State private var deleteConfirmationText: String = ""
    @State private var isDeletingAccount: Bool = false
    @State private var deleteErrorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    profileHeader
                    
                    // Username Section
                    usernameSection
                    
                    // Password Section
                    passwordSection
                    
                    // Delete Account Section
                    deleteAccountSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            loadCurrentUsername()
        }
        .sheet(isPresented: $showingDeleteConfirmation) {
            deleteConfirmationSheet
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                )
            
            Text(userDataProvider.currentUser?.username ?? "Username")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Username Section
    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingUsernameSection.toggle()
                }
                if showingUsernameSection {
                    loadCurrentUsername()
                }
            }) {
                HStack {
                    Image(systemName: "person.text.rectangle")
                        .foregroundColor(.pink)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Change Username")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Update your display name")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingUsernameSection ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            if showingUsernameSection {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Username")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter new username", text: $newUsername)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        SecureField("Enter current password", text: $usernamePassword)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    if let message = usernameSuccessMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 4)
                    }
                    
                    if let message = usernameErrorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                    
                    Button(action: changeUsername) {
                        HStack {
                            if isChangingUsername {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Update Username")
                                .font(.custom("Georgia", size: 16))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canChangeUsername ? Color.pink : Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .disabled(!canChangeUsername || isChangingUsername)
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }
    
    // MARK: - Password Section
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPasswordSection.toggle()
                }
                if showingPasswordSection {
                    clearPasswordFields()
                }
            }) {
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.pink)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Change Password")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Update your account password")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingPasswordSection ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            if showingPasswordSection {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        SecureField("Enter current password", text: $currentPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        SecureField("Enter new password", text: $newPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        Text("Must be at least 10 characters with uppercase, lowercase, number, and special character")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    if let message = passwordSuccessMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 4)
                    }
                    
                    if let message = passwordErrorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                    
                    Button(action: changePassword) {
                        HStack {
                            if isChangingPassword {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Update Password")
                                .font(.custom("Georgia", size: 16))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canChangePassword ? Color.pink : Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .disabled(!canChangePassword || isChangingPassword)
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text("Permanently delete your account and all data")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.4))
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Delete Confirmation Sheet
    private var deleteConfirmationSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Warning Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 20)
                    
                    // Warning Text
                    VStack(spacing: 12) {
                        Text("Delete Account")
                            .font(.custom("Georgia", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("This action cannot be undone. All your data, posts, and account information will be permanently deleted.")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Confirmation Input
                    VStack(spacing: 12) {
                        Text("Type 'DELETE' to confirm:")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("DELETE", text: $deleteConfirmationText)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 20)
                    }
                    
                    if let error = deleteErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: deleteAccount) {
                            HStack {
                                if isDeletingAccount {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text("Delete Account Forever")
                                    .font(.custom("Georgia", size: 16))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canDeleteAccount ? Color.red : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .disabled(!canDeleteAccount || isDeletingAccount)
                        .padding(.horizontal, 20)
                        
                        Button("Cancel") {
                            showingDeleteConfirmation = false
                            deleteConfirmationText = ""
                            deleteErrorMessage = nil
                        }
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Computed Properties
    private var canChangeUsername: Bool {
        !newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newUsername.count >= 3 &&
        !usernamePassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newUsername != (userDataProvider.currentUser?.username ?? "")
    }
    
    private var canChangePassword: Bool {
        !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 10
    }
    
    private var canDeleteAccount: Bool {
        deleteConfirmationText.uppercased() == "DELETE"
    }
    
    // MARK: - Helper Methods
    private func loadCurrentUsername() {
        newUsername = userDataProvider.currentUser?.username ?? ""
    }
    
    private func clearPasswordFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        passwordSuccessMessage = nil
        passwordErrorMessage = nil
    }
    
    private func changeUsername() {
        guard canChangeUsername else { return }
        
        isChangingUsername = true
        usernameSuccessMessage = nil
        usernameErrorMessage = nil
        
        Task {
            do {
                try await ProfileUpdateService.changeUsername(
                    newUsername: newUsername.trimmingCharacters(in: .whitespacesAndNewlines),
                    currentPassword: usernamePassword
                )
                
                // Refresh user data
                await userDataProvider.refreshUserData()
                
                await MainActor.run {
                    usernameSuccessMessage = "Username updated successfully!"
                    usernamePassword = ""
                    isChangingUsername = false
                    HapticFeedbackManager.shared.successNotification()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        usernameSuccessMessage = nil
                    }
                }
                
            } catch {
                await MainActor.run {
                    usernameErrorMessage = error.localizedDescription
                    isChangingUsername = false
                    HapticFeedbackManager.shared.errorNotification()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        usernameErrorMessage = nil
                    }
                }
            }
        }
    }
    
    private func changePassword() {
        guard canChangePassword else { return }
        
        isChangingPassword = true
        passwordSuccessMessage = nil
        passwordErrorMessage = nil
        
        Task {
            do {
                try await ProfileUpdateService.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    passwordSuccessMessage = "Password updated successfully!"
                    clearPasswordFields()
                    isChangingPassword = false
                    HapticFeedbackManager.shared.successNotification()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        passwordSuccessMessage = nil
                    }
                }
                
            } catch {
                await MainActor.run {
                    passwordErrorMessage = error.localizedDescription
                    isChangingPassword = false
                    HapticFeedbackManager.shared.errorNotification()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        passwordErrorMessage = nil
                    }
                }
            }
        }
    }
    
    private func deleteAccount() {
        guard deleteConfirmationText.uppercased() == "DELETE" else { return }
        
        isDeletingAccount = true
        deleteErrorMessage = nil
        
        Task {
            do {
                try await ProfileUpdateService.deleteAccount()
                
                // Account deleted successfully - sign out user
                await MainActor.run {
                    // Clear the confirmation and reset state
                    deleteConfirmationText = ""
                    isDeletingAccount = false
                    
                    // Sign out user (this will redirect to auth flow)
                    AuthenticationService.shared.logout()
                    
                    // Show success feedback
                    HapticFeedbackManager.shared.successNotification()
                }
                
            } catch {
                await MainActor.run {
                    deleteErrorMessage = error.localizedDescription
                    isDeletingAccount = false
                    deleteConfirmationText = ""
                    HapticFeedbackManager.shared.errorNotification()
                    
                    // Show error in a new alert
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDeleteError()
                    }
                }
            }
        }
    }
    
    private func showDeleteError() {
        // This could be implemented as a toast or another alert
        // For now, we'll just print the error (you might want to add a toast system)
        print("[EditProfileView]: Delete account error: \(deleteErrorMessage ?? "Unknown error")")
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Preview
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditProfileView()
                .environmentObject(UserDataProvider.shared)
        }
        .preferredColorScheme(.dark)
    }
}
