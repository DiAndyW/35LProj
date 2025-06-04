//
//  ProfilePostCard.swift
//  uclamoods
//
//  Created by David Sun on 6/4/25.
//

import SwiftUI

struct ProfilePostHeaderView: View {
    let timestamp: String
    let location: SimpleLocation?
    let people: [String]?
    
    var body: some View {
        HStack {
            VStack(){
                if let timestampParts = DateFormatterUtility.formatTimestampParts(timestampString: timestamp) {
                    Text("\(timestampParts.relativeDate), \(timestampParts.absoluteDate)")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
            
            Spacer()
            
            let hasLocation = location?.name != nil && !(location?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            if hasLocation{
                VStack(alignment: .trailing, spacing: 5) {
                    // Location
                    if let locationName = location?.name, !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text(locationName)
                                .font(.custom("Georgia", size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1).truncationMode(.tail)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}
struct ProfilePostPeopleView: View {
    let people: [String]?

    var body: some View {
        let hasPeople = people != nil && !(people?.isEmpty ?? true)
        if hasPeople{
            if let peopleArray = people, !peopleArray.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: peopleArray.count > 1 ? "person.2.fill" : "person.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(peopleArray.joined(separator: ", "))
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2).truncationMode(.tail)
                }
            }
        }
    }
}


struct ProfilePostCardEmotionView: View {
    let emotion: SimpleEmotion
    
    var body: some View {
        VStack(spacing: 0) {
            Text(emotion.name)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.bold)
                .foregroundColor(emotion.color ?? .white)
                .lineLimit(1)
            EmotionRadarChartView(emotion: EmotionDataProvider.getEmotion(byName: emotion.name)!, showText: false)
                .frame(width:100, height: 100)
                .offset(y: -3)
        }
    }
}

struct ProfilePostCard: View {
    let post: FeedItem
    let openDetailAction: () -> Void
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    @State private var isLiked: Bool = false
    @State private var currentLikesCount: Int = 0
    @State private var displayUsername: String = ""
    @State private var isLoadingUsername: Bool = false
    @State private var usernameFetchFailed: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            ProfilePostHeaderView(
                timestamp: post.timestamp,
                location: post.location,
                people: post.people
            )
            .padding(.horizontal, 16)
            
            HStack(spacing: 0) {
                ProfilePostCardEmotionView(emotion: post.emotion)
                MoodPostCardContentView(content: post.content)
            }
            .frame(maxHeight: 120)
            
            
            HStack(){
                ProfilePostPeopleView(people: post.people)
                Spacer()
                MoodPostCardActionsView(
                    isLiked: $isLiked,
                    currentLikesCount: $currentLikesCount,
                    commentsCount: post.commentsCount ?? 0,
                    likeAction: handleLikeButtonTapped,
                    commentButtonAction: openDetailAction
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(8)
        .background(Color.white.opacity(0.075))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(post.emotion.color?.opacity(0.6) ?? Color.white.opacity(0.1), lineWidth: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            if let userId = userDataProvider.currentUser?.id { //
                self.isLiked = post.likes?.userIds.contains(userId) ?? false
            } else {
                self.isLiked = false
            }
            self.currentLikesCount = post.likes?.count ?? post.likesCount ?? 0
            loadUsername()
        }
    }
    
    private func loadUsername() {
        isLoadingUsername = true
        usernameFetchFailed = false
        displayUsername = "Loading..."
        
        fetchUsername(for: post.userId) { result in //
            isLoadingUsername = false
            switch result {
                case .success(let fetchedName):
                    self.displayUsername = fetchedName
                case .failure(let error):
                    print("Failed to fetch username for \(post.userId): \(error.localizedDescription)")
                    self.displayUsername = "User"
                    self.usernameFetchFailed = true
            }
        }
    }
    
    private func handleLikeButtonTapped() {
        guard let currentUserID = userDataProvider.currentUser?.id else { //
            return
        }
        
        // UI Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Optimistic UI update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLiked.toggle()
            if isLiked {
                currentLikesCount += 1
            } else {
                currentLikesCount -= 1
            }
        }
        
        LikeService.updateLikeStatus(for: post.id, userId: currentUserID) { result in //
            switch result {
                case .success(let updateResponse):
                    self.currentLikesCount = updateResponse.likesCount
                    print("Like status successfully updated via LikeService for post \(post.id). New count: \(updateResponse.likesCount)")
                case .failure(let error):
                    print("Failed to update like status via LikeService for post \(post.id): \(error.localizedDescription)")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                        if isLiked {
                            currentLikesCount += 1
                        } else {
                            currentLikesCount -= 1
                        }
                    }
            }
        }
    }
}
