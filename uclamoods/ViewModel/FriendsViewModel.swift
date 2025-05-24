//
//  FriendsViewModel.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/22/25.
//

import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let friendsService = FriendsService()
    
    func loadFriends() {
        isLoading = true
        Task {
            do {
                friends = try await friendsService.fetchFriends()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
