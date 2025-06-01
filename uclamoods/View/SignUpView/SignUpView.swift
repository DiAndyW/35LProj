import SwiftUI

// Helper struct for standard TextFields to reduce repetition and improve consistency.
struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil // For better autofill suggestions
    var autocapitalization: UITextAutocapitalizationType = .none
    var disableAutocorrection: Bool = true

    private let fieldHeight: CGFloat = 50 // Standard tappable height
    private let fieldCornerRadius: CGFloat = 10 // Modern rounded corners

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7)) // Softer label color

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .frame(height: fieldHeight)
                .padding(.horizontal)
                .foregroundColor(.white) // Input text color
                .background(Color.white.opacity(0.08)) // Subtle background for the field
                .cornerRadius(fieldCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: fieldCornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5) // Thin, subtle border
                )
                .keyboardType(keyboardType)
                .textContentType(textContentType) // Improves autofill
                .autocapitalization(autocapitalization)
                .disableAutocorrection(disableAutocorrection)
        }
    }
}

// Helper struct for SecureFields, styled consistently with FormField.
struct SecureFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType? = .newPassword // Hint for password managers

    private let fieldHeight: CGFloat = 50
    private let fieldCornerRadius: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))

            SecureField(placeholder, text: $text)
                .font(.system(size: 16))
                .frame(height: fieldHeight)
                .padding(.horizontal)
                .foregroundColor(.white)
                .background(Color.white.opacity(0.08))
                .cornerRadius(fieldCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: fieldCornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .textContentType(textContentType)
                .autocapitalization(.none) // Passwords should not be autocapitalized
                .disableAutocorrection(true) // Typically not needed for passwords
        }
    }
}


struct SignUpView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    // Styling constants for consistency
    private let primaryButtonHeight: CGFloat = 52
    private let formHorizontalPadding: CGFloat = 24
    private let mainStackSpacing: CGFloat = 25 // Spacing between major sections

    var body: some View {
        ZStack {
            // Background: A darker, more subtle gradient
            Color.black
                        .edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) { // Ensures content fits all screen sizes
                VStack(spacing: mainStackSpacing) {
                    
                    // Top Spacer: Pushes content down slightly from the very top edge.
                    // Adjust height as needed or use .padding(.top) on the VStack.
                    Spacer().frame(height: UIScreen.main.bounds.height * 0.05)

                    // App Title
                    Text("Morii")
                        .font(.system(size: 48, weight: .bold, design: .rounded)) // Modern, friendly rounded font
                        .foregroundColor(.white)
                       
                    // View Title/Subtitle
                    Text("Create Your Account")
                        .font(.system(size: 26, weight: .semibold)) // Clear and professional
                        .foregroundColor(Color.white.opacity(0.85)) // Slightly softer white
                        .padding(.bottom, mainStackSpacing / 2) // Extra space after this title

                    // Form Fields Group
                    VStack(alignment: .center, spacing: 18) { // Consistent spacing between fields
                        FormField(
                            title: "Username",
                            placeholder: "Choose a username",
                            text: $username,
                            textContentType: .username // For autofill
                        )
                        FormField(
                            title: "Email Address",
                            placeholder: "you@example.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress // For autofill
                        )
                        SecureFormField(
                            title: "Password",
                            placeholder: "Create a strong password",
                            text: $password,
                            textContentType: .newPassword // For password manager suggestions
                        )
                    }
                    .padding(.horizontal, formHorizontalPadding) // Side padding for the form section

                    // Spacer before the primary button
                    Spacer().frame(height: mainStackSpacing / 2)

                    // Sign Up Button (Primary Action)
                    Button(action: {
                        performHapticFeedback()
                        // TODO: Implement your account creation logic
                        // Example: authViewModel.signUp(username: username, email: email, password: password)
                        router.navigateToCompleteProfile() // Placeholder navigation
                        print("Sign Up Tapped: Username - \(username), Email - \(email)")
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black) // Text color for contrast on a light button
                            .frame(maxWidth: .infinity) // Full width button
                            .frame(height: primaryButtonHeight)
                            .background(Color.white) // A bright, clean, and prominent button
                            .cornerRadius(primaryButtonHeight / 3) // Responsive rounding
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4) // Subtle shadow
                    }
                    .padding(.horizontal, formHorizontalPadding)

                    // Navigation to Sign In Screen (Secondary Action)
                    Button(action: {
                        performHapticFeedback(style: .light) // Lighter feedback for secondary actions
                        router.navigateToSignIn() // Placeholder navigation
                        print("Navigate to Sign In Tapped")
                    }) {
                        HStack(spacing: 4) { // Spacing between the two text parts
                            Text("Already have an account?")
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.6)) // Less prominent
                            Text("Sign In")
                                .font(.system(size: 15, weight: .bold)) // More prominent
                                .foregroundColor(Color.white.opacity(0.9)) // Brighter to stand out
                        }
                    }
                    .padding(.top, mainStackSpacing / 2) // Space above this button
                    
                    // Bottom Spacer: Pushes content upwards if it's not enough to fill the ScrollView,
                    // ensuring the "Sign In" button doesn't always stick to the absolute bottom.
                    Spacer()
                }
                .padding(.bottom, 30) // Padding at the very bottom of the scrollable content
            }
        }
        // Apply gentle spring animations to state changes for a more fluid feel
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: username)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: email)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: password)
        // .navigationBarHidden(true) // Uncomment if this view is part of a NavigationView and you want to hide the bar
        // .statusBar(hidden: true) // Consider if you want a fully immersive full-screen experience
    }

    /// Helper function to trigger haptic feedback.
    private func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let feedback = UIImpactFeedbackGenerator(style: style)
        feedback.prepare()
        feedback.impactOccurred()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit) e.g., "FFF"
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit) e.g., "FFFFFF"
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit) e.g., "FFFFFFFF"
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: // Default to clear if invalid hex
            (a, r, g, b) = (0, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview Provider for SwiftUI Canvas
struct ModernCleanSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(MoodAppRouter()) // Provide the dummy router for the preview
    }
}
