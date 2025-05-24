//
//  SignInView.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/10/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .center, spacing: 15) {
                    Text("Morii")
                        .font(.custom("Georgia", size: 60))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(alignment: .center)
                    Text("Log In")
                        .font(.custom("Georgia", size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
            
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email Address")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(alignment: .leading)
                        TextField("Required",text: $email)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .font(.custom("Georgia", size: 20).weight(.bold))
                            .frame(width: 300)
                        
                        Text("Password")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(alignment: .leading)
                        SecureField("Required",text: $password)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .font(.custom("Georgia", size: 20))
                            .frame(width: 300)
                        
                        Button(action: {
                            print("Forgot password tapped")
                        }) {
                            Text("Forgot Password?")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    
                    //need to add logic here to validate login info
                    //call to backend
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        
                        router.navigateToHome()
                    }) {
                        Text("Log In")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 60)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        
                        router.navigateToSignUp()
                    }) {
                        Text("Sign Up")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 60)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    
                
                }
            
            }
        }
        
    }
}

#Preview {
    SignInView()
        .environmentObject(MoodAppRouter())
}
