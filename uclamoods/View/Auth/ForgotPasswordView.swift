import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @FocusState private var isCodeFieldFocused: Bool
    
    @State private var currentStep: Step = .enterEmail
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    enum Step {
        case enterEmail
        case enterCode
        case resetPassword
        case success
    }
    
    // Styling constants
    private let primaryButtonHeight: CGFloat = 52
    private let formHorizontalPadding: CGFloat = 24
    private let mainStackSpacing: CGFloat = 25
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "202020"), Color(hex: "181818")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        if currentStep == .enterEmail {
                            dismiss()
                        } else if currentStep != .success {
                            withAnimation {
                                currentStep = .enterEmail
                                errorMessage = ""
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                            Text(currentStep == .enterEmail ? "Back" : "Start Over")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, formHorizontalPadding)
                .padding(.top, 20)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: mainStackSpacing) {
                        switch currentStep {
                        case .enterEmail:
                            emailStepView
                        case .enterCode:
                            codeStepView
                        case .resetPassword:
                            passwordStepView
                        case .success:
                            successView
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .navigationBarHidden(true)
    }
    
    // MARK: - Step Views
    
    private var emailStepView: some View {
        VStack(spacing: mainStackSpacing) {
            // Title
            VStack(spacing: 12) {
                Text("Forgot Password?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Enter your email and we'll send you\na verification code")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer().frame(height: 20)
            
            // Email field
            VStack(spacing: 18) {
                FormField(
                    title: "Email Address",
                    placeholder: "you@example.com",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
            }
            .padding(.horizontal, formHorizontalPadding)
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, formHorizontalPadding)
            }
            
            Spacer().frame(height: 20)
            
            // Submit button
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(height: primaryButtonHeight)
            } else {
                Button(action: sendVerificationCode) {
                    Text("Send Code")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: primaryButtonHeight)
                        .background(Color.white)
                        .cornerRadius(primaryButtonHeight / 3)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .disabled(email.isEmpty || !isValidEmail(email))
                .opacity(email.isEmpty || !isValidEmail(email) ? 0.6 : 1.0)
                .padding(.horizontal, formHorizontalPadding)
            }
        }
    }
    
    private var codeStepView: some View {
        VStack(spacing: mainStackSpacing) {
            // Title
            VStack(spacing: 12) {
                Text("Enter Verification Code")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("We sent a 6-digit code to\n\(email)")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: 20)

            // Code input
            VStack(spacing: 20) {
                // 6-digit code input
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitView(
                            digit: getDigit(at: index),
                            // 4a. Update isActive to reflect focus
                            isActive: isCodeFieldFocused && verificationCode.count == index
                        )
                    }
                }
                .padding(.horizontal, formHorizontalPadding)
                .onTapGesture { // 4b. Allow tapping digit views to focus
                    isCodeFieldFocused = true
                }

                // Hidden TextField for keyboard input
                TextField("", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode) // Helps with SMS autofill
                    .focused($isCodeFieldFocused) // 2. Apply .focused()
                    .frame(width: 1, height: 1) // Keep it minimal and hidden
                    .opacity(0.001) // Or .hidden() if opacity causes issues
                                    // For debugging, you can temporarily increase size/opacity
                                    // or add a .background(Color.blue.opacity(0.3))
                    .onChange(of: verificationCode) { newValue, oldValue in // 5. Improved onChange logic
                        // Ensure only digits are processed
                        let digitsOnly = newValue.filter { "0123456789".contains($0) }
                        
                        // Limit to 6 digits
                        let newCode = String(digitsOnly.prefix(6))

                        // Update the state variable only if it actually changed after filtering/truncating
                        // This prevents potential redraw cycles or issues.
                        if verificationCode != newCode {
                            verificationCode = newCode
                        }

                        // Auto-submit when 6 digits entered
                        if verificationCode.count == 6 {
                            // Optionally unfocus:
                            // isCodeFieldFocused = false
                            validateCode()
                        }
                    }
            }

            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, formHorizontalPadding)
            }

            // Resend button
            Button(action: sendVerificationCode) {
                Text("Resend Code")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
                    .underline()
            }
            .disabled(isLoading)

            Spacer().frame(height: 20)
            
            // Continue button
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(height: primaryButtonHeight)
            } else {
                Button(action: validateCode) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: primaryButtonHeight)
                        .background(verificationCode.count == 6 ? Color.white : Color.white.opacity(0.3))
                        .cornerRadius(primaryButtonHeight / 3)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .disabled(verificationCode.count != 6)
                .padding(.horizontal, formHorizontalPadding)
            }
        }
        .onAppear {
                    // 3. Auto-focus the hidden text field
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Reduced delay, 0.5s is quite long
                        isCodeFieldFocused = true
                    }
                }
    }
    
    private var passwordStepView: some View {
        VStack(spacing: mainStackSpacing) {
            // Title
            VStack(spacing: 12) {
                Text("Create New Password")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Choose a strong password for your account")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer().frame(height: 20)
            
            // Password fields
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    SecureFormField(
                        title: "New Password",
                        placeholder: "Enter new password",
                        text: $newPassword,
                        textContentType: .newPassword
                    )
                    
                    // Password strength indicator
                    if !newPassword.isEmpty {
                        PasswordStrengthIndicator(password: newPassword)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    SecureFormField(
                        title: "Confirm Password",
                        placeholder: "Re-enter new password",
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
                    .padding(.horizontal, formHorizontalPadding)
            }
            
            Spacer().frame(height: 20)
            
            // Reset button
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(height: primaryButtonHeight)
            } else {
                Button(action: resetPassword) {
                    Text("Reset Password")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: primaryButtonHeight)
                        .background(canResetPassword ? Color.white : Color.white.opacity(0.3))
                        .cornerRadius(primaryButtonHeight / 3)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .disabled(!canResetPassword)
                .padding(.horizontal, formHorizontalPadding)
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            // Success message
            VStack(spacing: 16) {
                Text("Password Reset!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your password has been successfully reset.\nYou can now sign in with your new password.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            // Return to login button
            Button(action: { dismiss() }) {
                Text("Return to Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: primaryButtonHeight)
                    .background(Color.white)
                    .cornerRadius(primaryButtonHeight / 3)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, formHorizontalPadding)
            
            Spacer().frame(height: 40)
        }
    }
    
    // MARK: - Helper Views & Functions
    
    private func getDigit(at index: Int) -> String {
        if index < verificationCode.count {
            let stringIndex = verificationCode.index(verificationCode.startIndex, offsetBy: index)
            return String(verificationCode[stringIndex])
        }
        return ""
    }
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var canResetPassword: Bool {
        isPasswordStrong(newPassword) && passwordsMatch
    }
    
    private func isPasswordStrong(_ password: String) -> Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let isLongEnough = password.count >= 10
        
        return hasUppercase && hasLowercase && hasDigit && hasSpecialChar && isLongEnough
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Actions
    
    private func sendVerificationCode() {
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await viewModel.requestPasswordReset(email: email)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        currentStep = .enterCode
                        verificationCode = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func validateCode() {
        guard verificationCode.count == 6 else { return }
        
        withAnimation {
            currentStep = .resetPassword
            errorMessage = ""
        }
    }
    
    private func resetPassword() {
        guard canResetPassword else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await viewModel.resetPasswordWithCode(
                    email: email,
                    code: verificationCode,
                    newPassword: newPassword
                )
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        currentStep = .success
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Code Digit View
struct CodeDigitView: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
                .frame(width: 50, height: 60)
            
            Text(digit)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Password Strength Indicator
struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strengthProgress: Double {
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
    
    private var strengthColor: Color {
        switch strengthProgress {
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
    
    private var strengthMessage: String {
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
    
    var body: some View {
        HStack {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    Rectangle()
                        .fill(strengthColor)
                        .frame(width: geometry.size.width * strengthProgress, height: 3)
                        .cornerRadius(1.5)
                        .animation(.easeInOut(duration: 0.2), value: strengthProgress)
                }
            }
            .frame(height: 3)
            
            Text(strengthMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(strengthColor)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}

// MARK: - View Model
class ForgotPasswordViewModel: ObservableObject {
    func requestPasswordReset(email: String) async throws {
        let endpoint = "/auth/forgot-password"
        let url = Config.apiURL(for: endpoint)
        
        let body = ["email": email]
        guard let encodedData = try? JSONEncoder().encode(body) else {
            throw NSError(domain: "EncodingError", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0)
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["msg"] {
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "APIError", code: httpResponse.statusCode)
        }
    }
    
    func resetPasswordWithCode(email: String, code: String, newPassword: String) async throws {
        let endpoint = "/auth/reset-password-with-code"
        let url = Config.apiURL(for: endpoint)
        
        let body = [
            "email": email,
            "code": code,
            "newPassword": newPassword
        ]
        
        guard let encodedData = try? JSONEncoder().encode(body) else {
            throw NSError(domain: "EncodingError", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0)
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["msg"] {
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "APIError", code: httpResponse.statusCode)
        }
    }
}

// MARK: - Preview
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
