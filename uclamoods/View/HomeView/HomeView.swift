//
//  HomeView.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/12/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0){
                VStack(alignment: .center, spacing:15) {
                    Text("Go Bruins!")
                        .font(.custom("Georgia", size:24))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.prepare()
                        feedback.impactOccurred()
                        
                        router.navigateToEnergySelection()
                    }) {
                        Text("Check In!")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                }
                
                Spacer()
                    
                MoodNavBar()
                    .ignoresSafeArea(edges: .bottom)
                        
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

//    .frame(width: geometry.size.width, height: geometry.size.height)

//    .background(
//        Color(UIColor.systemBackground)
//            .opacity(0.1)
//            .background(.ultraThinMaterial)
//    )
#Preview {
    HomeView()
        .environmentObject(MoodAppRouter())
}
