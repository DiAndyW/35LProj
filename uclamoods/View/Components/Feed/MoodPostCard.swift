import SwiftUI

// Assuming your data structures (FeedItem, SimpleEmotion, SimpleLocation)
// are defined as you provided.

struct MoodPostCard: View {
    let post: FeedItem // Using your defined FeedItem struct
    @EnvironmentObject private var userDataProvider: UserDataProvider
    @State private var isLiked: Bool = false
    @State private var currentLikesCount: Int = 0
    // let initialLikeCount: Int // Would come from post.likesCount
    // let initialCommentCount: Int // Would come from post.commentsCount

    @State private var displayUsername: String = ""
    @State private var isLoadingUsername: Bool = false
    @State private var usernameFetchFailed: Bool = false

    @ViewBuilder
    private var MoodPostHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isLoadingUsername {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(height: 18)
            } else {
                Text(displayUsername)
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(usernameFetchFailed ? .gray.opacity(0.7) : .white.opacity(0.9))
                    .lineLimit(1).truncationMode(.tail)
            }
            
            if let timestampParts = DateFormatterUtility.formatTimestampParts(timestampString: post.timestamp) {
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
    
    @ViewBuilder
    private var MoodPostEmotion: some View {
        VStack(spacing: 0) {
            EmotionRadarChartView(emotion: EmotionDataProvider.getEmotion(byName: post.emotion.name)!, showText: false)
                .frame(width:100, height: 100)
            Text(post.emotion.name)
                .font(.custom("Georgia", size: 12))
                .fontWeight(.bold)
                .foregroundColor(post.emotion.color ?? .white)
                .lineLimit(1)
                .offset(y: -4)
        }
        //.frame(width:80, height:90)
    }
    
    @ViewBuilder
    private var MoodPostText: some View {
        if let reasonText = post.content, !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(reasonText)
                .font(.custom("HelveticaNeue", size: 14))
                .foregroundColor(.white)
                .lineLimit(6).truncationMode(.tail)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private var MoodPostLocation: some View {
        VStack(alignment: .trailing, spacing: 5) {
            // Location
            if let locationName = post.location?.name, !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
            
            // People (Social Tags)
            if let peopleArray = post.people, !peopleArray.isEmpty {
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
    
    var body: some View {
        let hasLocation = post.location?.name != nil && !(post.location?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasPeople = post.people != nil && !(post.people?.isEmpty ?? true)
        
        VStack(alignment: .leading, spacing: 2) {
            //Main Post
            Group {
                //Username, Timestamp, Location, People
                HStack(){
                    VStack(){
                        MoodPostHeader
                        Spacer()
                    }
                    .padding(8)

                    Spacer()
                    
                    if hasLocation || hasPeople {
                        VStack(){
                            MoodPostLocation
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                //Post Content and Emotion Circle
                HStack(spacing: 0) {
                    
                    VStack(spacing: 0) {
                        MoodPostEmotion
                            //.offset(y: -4)
                        Spacer()
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        MoodPostText
                            .padding(8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        Spacer()
                    }
                    .padding(4)
                }
                .frame(maxWidth: .infinity)
                //.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }

            // MARK: - Interaction Buttons
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        handleLikeButtonTapped()
                    }
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                }) {
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

                Button(action: {
                    // TODO: Open comments view
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(post.commentsCount ?? 0)") // Displaying commentsCount from FeedItem
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 8)
        }
        .padding(8)
        .background(Color.white.opacity(0.075))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(post.emotion.color?.opacity(0.6) ?? Color.white.opacity(0.1), lineWidth: 2))
        .onAppear(){
            if let userId = userDataProvider.currentUser?.id {
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
        // Use a more generic placeholder while loading if post.isAnonymous could be true
        // For now, assuming fetchUsername will handle anonymous display if needed.
        displayUsername = "Loading..."
        print("Fetching username for \(post.userId)...")
        
        fetchUsername(for: post.userId) { result in // You might need to pass post.isAnonymous too
            isLoadingUsername = false
            switch result {
                case .success(let fetchedName):
                    self.displayUsername = fetchedName
                case .failure(let error):
                    print("Failed to fetch username for \(post.userId): \(error.localizedDescription)")
                    self.displayUsername = "User" // Fallback or use post.userId if appropriate
                    self.usernameFetchFailed = true
            }
        }
    }
    
    private func handleLikeButtonTapped() {
        guard let currentUserID = userDataProvider.currentUser?.id else {
            return
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLiked.toggle()
            if isLiked {
                currentLikesCount += 1
            } else {
                currentLikesCount -= 1
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        LikeService.updateLikeStatus(for: post.id, userId: currentUserID) { result in
            switch result {
                case .success(let updateResponse):
                    self.currentLikesCount = updateResponse.likesCount
                    // Potentially update self.isLiked based on a more detailed response if needed
                    print("Like status successfully updated via LikeService for post \(post.id). New count: \(updateResponse.likesCount)")
                case .failure(let error):
                    print("Failed to update like status via LikeService for post \(post.id): \(error.localizedDescription)")
                    // Revert optimistic UI update
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

// Add this to your FeedItem if you track current user's like state
extension FeedItem {
    var isLikedByCurrentUser: Bool? { // This is an example, add actual logic/property
        nil // Or true/false based on actual data
    }
}

// MARK: - Preview
/*
struct MoodPostCard_Previews: PreviewProvider {
    static var sampleEmotion = SimpleEmotion(
        name: "Joyful",
        pleasantness: 0.8, intensity: 0.7, clarity: 0.9, control: 0.6,
        color: .yellow
    )
    static var sampleLocation = SimpleLocation(name: "Royce Hall")

    static var samplePostFull = FeedItem(
        id: "1",
        userId: "user123",
        emotion: sampleEmotion,
        content: "Beautiful day on campus! Feeling really inspired after the lecture.",
        people: ["Classmates", "Professor K."],
        activities: ["Lecture", "Walking"],
        location: sampleLocation,
        timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600*2)), // 2 hours ago
        likesCount: 27,
        commentsCount: 4
    )
    
    static var samplePostMinimal = FeedItem(
        id: "2",
        userId: "user456",
        emotion: SimpleEmotion(name: "Focused", pleasantness: nil, intensity: nil, clarity: nil, control: nil, color: .blue),
        content: "Deep work session.",
        people: nil,
        activities: ["Coding"],
        location: nil,
        timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600*28)), // 28 hours ago
        likesCount: 5,
        commentsCount: 0
    )
    
     static var samplePostNoContent = FeedItem(
        id: "3",
        userId: "user789",
        emotion: SimpleEmotion(name: "Relaxed", pleasantness: nil, intensity: nil, clarity: nil, control: nil, color: .green),
        content: nil,
        people: ["Family"],
        activities: ["Dinner"],
        location: SimpleLocation(name: "Home"),
        timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600*72)), // 3 days ago
        likesCount: 12,
        commentsCount: 1
    )

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                MoodPostCard(post: samplePostFull)
                MoodPostCard(post: samplePostMinimal)
                MoodPostCard(post: samplePostNoContent)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.2))
        .preferredColorScheme(.dark)
    }
}
*/
