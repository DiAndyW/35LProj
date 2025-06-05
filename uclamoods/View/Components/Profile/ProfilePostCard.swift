import SwiftUI

struct ProfilePostCardHeaderView: View {
    let displayUsername: String
    let isLoadingUsername: Bool
    let usernameFetchFailed: Bool
    let timestamp: String
    let location: SimpleLocation?
    let people: [String]?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                let hasLocation = location?.name != nil && !(location?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                let hasPeople = people != nil && !(people?.isEmpty ?? true)
                
                if hasLocation || hasPeople {
                    VStack(alignment: .leading, spacing: 5) {
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
                    }
                }else{
                    HStack(spacing: 5) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No location or people data")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1).truncationMode(.tail)
                    }
                }
                Spacer()
            }
            
            Spacer()
            
            HStack {
                VStack(){
                    if let timestampParts = DateFormatterUtility.formatTimestampParts(timestampString: timestamp) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timestampParts.relativeDate)
                                .font(.custom("Georgia", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            Text(timestampParts.absoluteDate)
                                .font(.custom("Georgia", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct ProfilePostCardEmotionView: View {
    let emotion: SimpleEmotion
    
    var body: some View {
        VStack(spacing: 0) {
            Text(emotion.name)
                .font(.custom("Georgia", size: 16))
                .fontWeight(.bold)
                .foregroundColor(emotion.color ?? .white)
                .lineLimit(1)
                .offset(y: 5)
            EmotionRadarChartView(emotion: EmotionDataProvider.getEmotion(byName: emotion.name)!, showText: false)
                .frame(width:130, height: 130)
                .offset(y: -3)
        }
    }
}

struct ProfilePostCardContentView: View {
    let content: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if let reasonText = content, !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(reasonText)
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(6).truncationMode(.tail)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }
            Spacer()
        }
    }
}

struct ProfilePostCardActionsView: View {
    @Binding var isLiked: Bool
    @Binding var currentLikesCount: Int
    let commentsCount: Int
    let likeAction: () -> Void
    let commentButtonAction: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: likeAction) {
                HStack(spacing: 5) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isLiked ? .red : .white.opacity(0.7))
                        .scaleEffect(isLiked ? 1.15 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isLiked)
                    Text("\(currentLikesCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .animation(nil, value: currentLikesCount)
                }
            }
            .buttonStyle(.plain)
            
            Button(action: commentButtonAction) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(commentsCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 2){
            ProfilePostCardHeaderView(
                displayUsername: displayUsername,
                isLoadingUsername: isLoadingUsername,
                usernameFetchFailed: usernameFetchFailed,
                timestamp: post.timestamp,
                location: post.location,
                people: post.people
            )
            .padding(.bottom, 4)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(post.emotion.color?.opacity(0.3) ?? Color.white.opacity(0.1), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ProfilePostCardEmotionView(emotion: post.emotion)
                    ProfilePostCardContentView(content: post.content)
                }
                .frame(maxHeight: 120)
                
                HStack(){
                    Spacer()
                    ProfilePostCardActionsView(
                        isLiked: $isLiked,
                        currentLikesCount: $currentLikesCount,
                        commentsCount: post.commentsCount ?? 0,
                        likeAction: handleLikeButtonTapped,
                        commentButtonAction: openDetailAction
                    )
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.02))
        }
        .cornerRadius(20)
        .background(Color.white.opacity(0.05))
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
