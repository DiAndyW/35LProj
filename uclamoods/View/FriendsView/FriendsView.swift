////
////  FriendsView.swift
////  uclamoods
////
////  Created by Di Xuan Wang on 5/16/25.
////
//
//import SwiftUI
//
//struct FriendsView: View {
//    @EnvironmentObject private var router: MoodAppRouter
//    @StateObject private var viewModel = FriendsViewModel()
//    
//    var body: some View {
//        ZStack{
//            Color.black
//                .edgesIgnoringSafeArea(.all)
//            VStack(spacing: 0) {
//                
//                //header
//                VStack(alignment: .center, spacing:15) {
//                    Text("Friends!")
//                        .font(.custom("Georgia", size:28))
//                        .foregroundColor(.white)
//                        .fontWeight(.bold)
//                }
//                .padding(.top, 20)
//                .padding(.horizontal)
//                
//                //friends list
//                if viewModel.isLoading {
//                    Spacer()
//                    ProgressView("Loading friends...")
//                        .foregroundColor(.white)
//                    Spacer()
//                } else {
//                    ScrollView {
//                        LazyVStack(spacing: 12) {
//                            ForEach(viewModel.friends) { friend in
//                                FriendCard(friend: friend)
//                            }
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 20)
//                        .padding(.bottom, 100)
//                    }
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
//        .onAppear {
//            viewModel.loadFriends()
//        }
//        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
//            Button("OK") { viewModel.errorMessage = nil }
//        } message: {
//            Text(viewModel.errorMessage ?? "")
//        }
//    }
//}
//
//#Preview {
//    FriendsView()
//        .environmentObject(MoodAppRouter())
//}
