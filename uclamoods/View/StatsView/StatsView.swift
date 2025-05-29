////
////  StatsView.swift
////  uclamoods
////
////  Created by Di Xuan Wang on 5/16/25.
////
//
//import SwiftUI
//
//struct StatsView: View {
//    @EnvironmentObject private var router: MoodAppRouter
//    
//    
//    var body: some View {
//        ZStack{
//            Color.black
//                .edgesIgnoringSafeArea(.all)
//            VStack(spacing: 0) {
//                VStack(alignment: .center, spacing:15) {
//                    Text("This is the stats page!")
//                        .font(.custom("Georgia", size:24))
//                        .foregroundColor(.white)
//                }
//                    
//                Spacer()
//                    
//                MoodNavBar()
//                    .ignoresSafeArea(edges: .bottom)
//                    
//            }
////                .frame(width: geometry.size.width, height: geometry.size.height)
//            
//        }
//        .edgesIgnoringSafeArea(.bottom)
//    }
//}
//
//#Preview {
//    StatsView()
//        .environmentObject(MoodAppRouter())
//}
