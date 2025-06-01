import SwiftUI

// MARK: - Network & Data Models

struct LoginCredentials: Codable {
    let email: String
    let password: String
}

struct SuccessfulLoginResponse: Codable {
    let access: String
    let refresh: String
}

struct ErrorLoginResponse: Codable {
    let msg: String
}


// MARK: - Modern Sign In View

struct SignInView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    @State private var email = ""
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var feedbackMessage = ""
    @State private var isLoggedIn = false // In a real app, this would likely be managed by a global auth state

    // Styling constants
    private let primaryButtonHeight: CGFloat = 52
    private let formHorizontalPadding: CGFloat = 24
    private let mainStackSpacing: CGFloat = 25

    // MARK: - Login Logic
    func attemptLogin() {
        isLoading = true
        feedbackMessage = ""
        performHapticFeedback()
        
        let url = Config.apiURL(for: "/auth/login") // Use your actual endpoint
        let credentials = LoginCredentials(email: email, password: password)
        
        guard let encodedCredentials = try? JSONEncoder().encode(credentials) else {
            feedbackMessage = "Could not prepare login data."
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedCredentials
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    feedbackMessage = "Network error: \(error.localizedDescription)"
                    isLoggedIn = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    feedbackMessage = "Invalid response from server."
                    isLoggedIn = false
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    do {
                        let successResponse = try JSONDecoder().decode(SuccessfulLoginResponse.self, from: data)
                        // Handle successful login: store tokens, update auth state
                        print("Access Token: \(successResponse.access)")
                        print("Refresh Token: \(successResponse.refresh)")
                        
                        feedbackMessage = "Login Successful!" // May not be seen if navigating immediately
                        isLoggedIn = true
                        // IMPORTANT: In a real app, navigate away after successful login
                        // For example, by changing a global state that ContentView observes,
                        // or by calling a router method that updates the main view.
                        router.navigateToMainApp()
                    } catch {
                        feedbackMessage = "Login successful, but token parsing failed: \(error.localizedDescription)"
                        // Depending on app logic, isLoggedIn might be true or false here.
                        // If tokens are critical for the app to function, set isLoggedIn = false.
                        isLoggedIn = false // Or true, if partial success is acceptable
                    }
                } else {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorLoginResponse.self, from: data)
                        feedbackMessage = errorResponse.msg
                    } catch {
                        feedbackMessage = "Login failed (Status: \(httpResponse.statusCode)). Could not parse error."
                    }
                    isLoggedIn = false
                }
            }
        }.resume()
    }

    private func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let feedback = UIImpactFeedbackGenerator(style: style)
        feedback.prepare()
        feedback.impactOccurred()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black
                        .edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: mainStackSpacing) {
                    // This conditional rendering of "Welcome" vs Login Form might be handled
                    // by navigating to a different view in a real app upon successful login.
                    // For this example, we keep it within SignInView as per original structure.
                    if isLoggedIn && feedbackMessage.contains("Successful") { // Show welcome only on explicit success
                        loggedInView
                    } else {
                        loginFormView
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.2), value: email)
        .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.2), value: password)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
        // .navigationBarHidden(true) // Uncomment if used within a NavigationView
    }

    // MARK: - Subviews for Readability
    @ViewBuilder
    private var loginFormView: some View {
        Spacer().frame(height: UIScreen.main.bounds.height * 0.05) // Top spacing

        Text("Morii") // App Title
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.white)
        
        Text("Welcome Back") // Subtitle
            .font(.system(size: 26, weight: .semibold))
            .foregroundColor(Color.white.opacity(0.85))
            .padding(.bottom, mainStackSpacing / 2)

        VStack(alignment: .center, spacing: 18) { // Form fields
            FormField(
                title: "Email Address",
                placeholder: "you@example.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            SecureFormField(
                title: "Password",
                placeholder: "Enter your password",
                text: $password,
                textContentType: .password // For existing passwords
            )
            
            HStack { // Forgot Password link
                Spacer()
                Button(action: {
                    performHapticFeedback(style: .light)
                    print("Forgot Password Tapped")
                    // TODO: Implement forgot password navigation/logic
                }) {
                    Text("Forgot Password?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                        .underline()
                }
            }
            .padding(.top, -5) // Adjust to be closer to the password field
        }
        .padding(.horizontal, formHorizontalPadding)

        // Feedback Message for errors
        if !feedbackMessage.isEmpty && !isLoggedIn { // Show only if error and not in a "successful login" state
            Text(feedbackMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.red) // Error messages in red
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, formHorizontalPadding)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            // Maintain space if no error message, for consistent button positioning
            Spacer().frame(height: (mainStackSpacing / 1.5) + (feedbackMessage.isEmpty ? 24 : 0) ) // Adjust height to be similar to with error
        }

        // Loading Indicator or Log In Button
        if isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5) // Slightly larger indicator
                .frame(height: primaryButtonHeight)
                .padding(.top, feedbackMessage.isEmpty || isLoggedIn ? mainStackSpacing / 2 : 0) // Dynamic top padding
        } else {
            Button(action: attemptLogin) { // Primary Log In button
                Text("Log In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black) // Dark text on light button
                    .frame(maxWidth: .infinity)
                    .frame(height: primaryButtonHeight)
                    .background(Color.white) // Prominent white button
                    .cornerRadius(primaryButtonHeight / 3) // Responsive corner radius
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4) // Subtle shadow
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading) // Disable if fields empty or loading
            .padding(.horizontal, formHorizontalPadding)
            .padding(.top, feedbackMessage.isEmpty || isLoggedIn ? mainStackSpacing / 2 : 0)
        }
        
        // Navigation to Sign Up Screen (Secondary Action)
        Button(action: {
            performHapticFeedback(style: .light)
            router.navigateToSignUp()
        }) {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.6))
                Text("Sign Up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.9)) // Make "Sign Up" stand out
            }
        }
        .padding(.top, mainStackSpacing / 1.5)
        Spacer() // Pushes content up if screen is tall
    }
    
    @ViewBuilder
    private var loggedInView: some View {
        Spacer().frame(height: UIScreen.main.bounds.height * 0.2) // Center content

        Image(systemName: "checkmark.circle.fill") // Success icon
            .font(.system(size: 60, weight: .semibold))
            .foregroundColor(Color.green) // Green for success
            .padding(.bottom, 10)

        Text("Login Successful!")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
        
        Text("Welcome back to Morii.") // Additional welcome message
            .font(.system(size: 18))
            .foregroundColor(Color.white.opacity(0.8))
            .padding(.top, 5)

        Spacer().frame(height: 30)

        Button(action: { // Log Out Button
            performHapticFeedback(style: .light)
            isLoggedIn = false // Reset state
            feedbackMessage = "" // Clear feedback
            email = "" // Clear fields
            password = ""
            // TODO: Implement actual logout logic (clear tokens, etc.)
            print("User Logged Out")
        }) {
            Text("Log Out")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: primaryButtonHeight)
                .background(Color.white.opacity(0.15)) // Subtle background for logout
                .cornerRadius(primaryButtonHeight / 3)
        }
        .padding(.horizontal, formHorizontalPadding)
        Spacer() // Push content to center
    }
}

// MARK: - Preview

struct ModernSignInView_Previews: PreviewProvider {
    static var previews: some View {
        // Ensure dummy MoodAppRouter and other dependencies are available for preview
        SignInView()
            .environmentObject(MoodAppRouter())
    }
}
