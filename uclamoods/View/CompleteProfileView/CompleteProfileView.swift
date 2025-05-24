//
//  CompleteProfileView.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/19/25.
//

import SwiftUI

struct CompleteProfileView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var profileImage: Image? = nil
    @State private var showingImagePicker = false
    @State private var inputUIImage: UIImage? = nil
    
    func loadImage() {
        guard let inputUIImage = inputUIImage else { return }
        profileImage = Image(uiImage: inputUIImage)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    
                    VStack(spacing: 10) {
                        Text("Complete your profile")
                            .font(.custom("Georgia", size: 25))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        VStack(alignment: .center) {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth:2)
                                    )
                            } else {
                                Image("default_profile_picture")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth:2)
                                    )
                            }

                            Button(action: {showingImagePicker = true}) {
                                Text("Choose Profile Picture")
                                    .font(.custom("Georgia", size: 16))
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            
                        }
                        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                            ImagePicker(image: $inputUIImage)
                        }
                        
                        //Username section with proper left alignment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.custom("Georgia", size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            TextField("Username", text: $username)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.25), lineWidth: 1))
                                .font(.custom("Georgia", size: 20).weight(.bold))
                        }
                        .frame(width: 300)
                        
                        //Display Name section with proper left alignment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.custom("Georgia", size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            TextField("Display Name", text: $displayName)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.25), lineWidth: 1))
                                .font(.custom("Georgia", size: 20).weight(.bold))
                        }
                        .frame(width: 300)
                    }
                    
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        
                        router.navigateToHome()
                    }) {
                        Text("Let's go!")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 60)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    CompleteProfileView()
        .environmentObject(MoodAppRouter())
}
