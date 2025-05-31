import SwiftUI
import Foundation

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

struct SignInView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    @State private var email = ""
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var feedbackMessage = ""
    @State private var isLoggedIn = false
    
    func attemptLogin() {
        isLoading = true
        feedbackMessage = ""
        
        let endpoint = "/auth/login"
        let url = Config.apiURL(for: endpoint)

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
                        feedbackMessage = "Login Successful!"
                        isLoggedIn = true
                        router.navigateToMainApp()
                    } catch {
                        feedbackMessage = "Successfully logged in, but failed to parse tokens: \(error.localizedDescription)"
                        isLoggedIn = true
                    }
                } else {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorLoginResponse.self, from: data)
                        feedbackMessage = errorResponse.msg
                    } catch {
                        feedbackMessage = "Login failed (Status: \(httpResponse.statusCode)). Could not parse error message."
                    }
                    isLoggedIn = false
                }
            }
        }.resume()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .center, spacing: 15) {
                    if isLoggedIn {
                        Text("Welcome!")
                            .font(.custom("Georgia", size: 40))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text(feedbackMessage)
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.green)
                        Button("Log Out") {
                            isLoggedIn = false
                            feedbackMessage = ""
                            email = ""
                            password = ""
                        }
                        .padding(.top)
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.white)
                    } else {
                        Text("Morii")
                            .font(.custom("Georgia", size: 60))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Log In")
                            .font(.custom("Georgia", size: 40))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email Address")
                                .font(.custom("Georgia", size: 20)).bold().foregroundColor(.white)
                            TextField("Required", text: $email)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .keyboardType(.emailAddress)
                                .padding().foregroundColor(.white)
                                .background(Color.white.opacity(0.1)).cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.25)))
                                .font(.custom("Georgia", size: 20).weight(.bold)).frame(width: 300)
                            
                            Text("Password")
                                .font(.custom("Georgia", size: 20)).bold().foregroundColor(.white)
                            SecureField("Required", text: $password)
                                .textInputAutocapitalization(.never)
                                .padding().foregroundColor(.white)
                                .background(Color.white.opacity(0.1)).cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.25)))
                                .font(.custom("Georgia", size: 20)).frame(width: 300)
                            
                            Button(action: { print("Forgot password tapped") }) {
                                Text("Forgot Password?")
                                    .font(.custom("Georgia", size: 16)).foregroundColor(.white).underline()
                            }
                        }
                        
                        if !feedbackMessage.isEmpty && !isLoggedIn {
                            Text(feedbackMessage)
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.red)
                                .padding(.vertical, 5)
                                .multilineTextAlignment(.center)
                                .frame(width: 300)
                        }
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 300, height: 60)
                        } else {
                            Button(action: attemptLogin) {
                                Text("Log In")
                                    .font(.custom("Georgia", size: 20)).bold().foregroundColor(.white)
                                    .frame(width: 300, height: 60)
                                    .background(Color.white.opacity(0.1)).cornerRadius(20).shadow(radius: 5)
                            }
                            .disabled(email.isEmpty || password.isEmpty)
                        }
                        
                        // Sign Up button
                        Button(action: {
                            // router.navigateToSignUp()
                            print("Navigate to Sign Up Tapped")
                        }) {
                            Text("Sign Up")
                                .font(.custom("Georgia", size: 20)).bold().foregroundColor(.white)
                                .frame(width: 300, height: 60)
                                .background(Color.white.opacity(0.1)).cornerRadius(20).shadow(radius: 5)
                        }
                    }
                    Spacer() // Pushes content towards center/top
                }
                .padding() // Add padding to the VStack itself
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
        .environmentObject(MoodAppRouter())
    }
}
