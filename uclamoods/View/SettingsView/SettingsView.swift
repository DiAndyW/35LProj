//
//  SettingsView.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/16/25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    
    var body: some View {
        ZStack{
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                VStack(alignment: .center, spacing:15) {
                    Text("This is the settings page!")
                        .font(.custom("Georgia", size:24))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        
                        router.navigateToSignIn()
                    }) {
                        Text("Log Out")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 60)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                }
                
                Spacer()
                    
                MoodNavBar()
                    .ignoresSafeArea(edges: .bottom)
                    
            }
//                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    SettingsView()
        .environmentObject(MoodAppRouter())
}
