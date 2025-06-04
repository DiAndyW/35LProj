//
//  BlockedAccountsView.swift
//  uclamoods
//
//  Created by Yang Gao on 6/4/25.
//
import SwiftUI

struct BlockedAccountsView: View {
    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var statusMessage = ""
    @State private var showStatusMessage = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Status message
                if showStatusMessage {
                    HStack {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(statusMessage.contains("Failed") || statusMessage.contains("Error") ? .red : .green)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                }
                
                if isLoading {
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading blocked accounts...")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Failed to load blocked accounts")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Try Again") {
                            loadBlockedUsers()
                        }
                        .font(.custom("Georgia", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(25)
                        Spacer()
                    }
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No blocked accounts")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("You haven't blocked any users yet.")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(blockedUsers) { user in
                                BlockedUserRow(
                                    user: user,
                                    onUnblock: {
                                        unblockUser(user)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("Blocked Accounts")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            loadBlockedUsers()
        }
        .refreshable {
            loadBlockedUsers()
        }
    }
    
    private func loadBlockedUsers() {
        isLoading = true
        errorMessage = nil
        
        BlockedAccountsService.fetchBlockedUsers { result in
            isLoading = false
            switch result {
            case .success(let users):
                blockedUsers = users
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func unblockUser(_ user: BlockedUser) {
        showStatus("Unblocking \(user.username)...")
        
        BlockedAccountsService.unblockUser(userId: user.id) { result in
            switch result {
            case .success:
                // Remove from local list
                if let index = blockedUsers.firstIndex(where: { $0.id == user.id }) {
                    blockedUsers.remove(at: index)
                }
                showStatus("\(user.username) has been unblocked")
            case .failure(let error):
                showStatus("Failed to unblock \(user.username): \(error.localizedDescription)")
            }
        }
    }
    
    private func showStatus(_ message: String, duration: TimeInterval = 3.0) {
        statusMessage = message
        showStatusMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.3)) {
                showStatusMessage = false
            }
        }
    }
}

struct BlockedUserRow: View {
    let user: BlockedUser
    let onUnblock: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile picture placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button("Unblock") {
                onUnblock()
            }
            .font(.custom("Georgia", size: 14))
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
