import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    
    // Profanity filter and toast states
    @StateObject private var profanityFilter = ProfanityFilterService()
    @State private var showProfanityToast: Bool = false
    @State private var toastMessage: String = ""
    
    // Styling constants
    private let primaryButtonHeight: CGFloat = 52
    private let formHorizontalPadding: CGFloat = 24
    private let mainStackSpacing: CGFloat = 25
    
    private var isUsernameValid: Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedUsername.count >= 4 && profanityFilter.isContentAcceptable(text: trimmedUsername)
    }
    
    private func validateUsernameLength() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedUsername.isEmpty && trimmedUsername.count < 4 {
            toastMessage = "Username must be at least 4 characters long."
            showProfanityToast = true
            performHapticFeedback(style: .heavy)
        }
    }
    
    // Password validation
    private var passwordStrengthMessage: String {
        if password.isEmpty {
            return ""
        }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let isLongEnough = password.count >= 10
        
        if !isLongEnough {
            return "Must be at least 10 characters"
        } else if !hasUppercase {
            return "Add an uppercase letter"
        } else if !hasLowercase {
            return "Add a lowercase letter"
        } else if !hasDigit {
            return "Add a number"
        } else if !hasSpecialChar {
            return "Add a special character"
        } else {
            return "Strong password ✓"
        }
    }
    
    private var isPasswordStrong: Bool {
        passwordStrengthMessage == "Strong password ✓"
    }
    
    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    private var canSubmit: Bool {
        isUsernameValid && !email.isEmpty && isPasswordStrong && passwordsMatch
    }
    
    // MARK: - Username Validation
    private func validateUsername() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedUsername.isEmpty && !profanityFilter.isContentAcceptable(text: trimmedUsername) {
            toastMessage = "Username contains inappropriate language. Please choose a different username."
            showProfanityToast = true
            
            // Clear the username field
            username = ""
            performHapticFeedback(style: .heavy)
        }
    }
    
    // MARK: - Sign Up Logic
    func attemptSignUp() {
        guard canSubmit else { return }
        
        // Final validation before submission
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !profanityFilter.isContentAcceptable(text: trimmedUsername) {
            toastMessage = "Username contains inappropriate language. Please choose a different username."
            showProfanityToast = true
            return
        }
        
        isLoading = true
        errorMessage = ""
        performHapticFeedback()
        
        Task {
            do {
                _ = try await authService.register(
                    username: trimmedUsername,
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let feedback = UIImpactFeedbackGenerator(style: style)
        feedback.prepare()
        feedback.impactOccurred()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(spacing: mainStackSpacing) {
                Spacer().frame(height: UIScreen.main.bounds.height * 0.03)
                    .padding(.top, -5)
                
                Text("Morii")
                    .font(.custom("Georgia", size: 48))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, -20)
                
                Text("Moments That Stay")
                    .font(.custom("Chivo", size: 20))
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(.bottom, mainStackSpacing / 2)
                
                // Form Fields
                VStack(alignment: .center, spacing: 18) {
                    FormField(
                        title: "Username",
                        placeholder: "Choose a username (min 4 characters)",
                        text: $username,
                        textContentType: .username
                    )
                    .onSubmit {
                        validateUsernameLength()
                        validateUsername()
                    }
                    .onChange(of: username) { oldValue, newValue in
                        let trimmedUsername = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !trimmedUsername.isEmpty {
                            if trimmedUsername.count < 4 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if username == newValue {
                                        toastMessage = "Username must be at least 4 characters long."
                                        showProfanityToast = true
                                    }
                                }
                            } else if !profanityFilter.isContentAcceptable(text: trimmedUsername) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if username == newValue {
                                        toastMessage = "Username contains inappropriate language."
                                        showProfanityToast = true
                                    }
                                }
                            }
                        }
                    }
                    
                    FormField(
                        title: "Email Address",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SecureFormField(
                            title: "Password",
                            placeholder: "Create a strong password",
                            text: $password,
                            textContentType: .newPassword
                        )
                        
                        // Password strength indicator
                        if !password.isEmpty {
                            HStack {
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 3)
                                            .cornerRadius(1.5)
                                        
                                        Rectangle()
                                            .fill(passwordStrengthColor)
                                            .frame(width: geometry.size.width * passwordStrengthProgress, height: 3)
                                            .cornerRadius(1.5)
                                            .animation(.easeInOut(duration: 0.2), value: passwordStrengthProgress)
                                    }
                                }
                                .frame(height: 3)
                                
                                Text(passwordStrengthMessage)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(passwordStrengthColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SecureFormField(
                            title: "Confirm Password",
                            placeholder: "Re-enter your password",
                            text: $confirmPassword,
                            textContentType: .newPassword
                        )
                        
                        // Password match indicator
                        if !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(passwordsMatch ? .green : .red)
                                
                                Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(passwordsMatch ? .green : .red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, formHorizontalPadding)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.red)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 5)
                        .padding(.horizontal, formHorizontalPadding)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Spacer().frame(height: mainStackSpacing / 2)
                
                // Sign Up Button
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(height: primaryButtonHeight)
                } else {
                    Button(action: attemptSignUp) {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: primaryButtonHeight)
                            .background(canSubmit ? Color.white : Color.white.opacity(0.3))
                            .cornerRadius(primaryButtonHeight / 3)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canSubmit)
                    .padding(.horizontal, formHorizontalPadding)
                }
                
                // Sign In Navigation
                Button(action: {
                    performHapticFeedback(style: .light)
                    router.navigateToSignIn()
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.6))
                        Text("Sign In")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                }
                .padding(.top, mainStackSpacing / 2)
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: username)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: email)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: password)
        .alert("Account Created!", isPresented: $showingSuccessAlert) {
            Button("Sign In") {
                router.navigateToSignIn()
            }
        } message: {
            Text("Your account has been created successfully. Please sign in to continue.")
        }
        .toast(isShowing: $showProfanityToast, message: toastMessage, type: .error)
    }
    
    // MARK: - Password Strength Helpers
    private var passwordStrengthProgress: Double {
        let checks = [
            password.count >= 10,
            password.range(of: "[A-Z]", options: .regularExpression) != nil,
            password.range(of: "[a-z]", options: .regularExpression) != nil,
            password.range(of: "[0-9]", options: .regularExpression) != nil,
            password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        ]
        
        let passedChecks = checks.filter { $0 }.count
        return Double(passedChecks) / Double(checks.count)
    }
    
    private var passwordStrengthColor: Color {
        switch passwordStrengthProgress {
        case 0..<0.4:
            return .red
        case 0.4..<0.8:
            return .orange
        case 0.8...1.0:
            return .green
        default:
            return .gray
        }
    }
}

// MARK: - Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(MoodAppRouter())
    }
}
