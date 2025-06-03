import SwiftUI

// Assuming your data structures (FeedItem, SimpleEmotion, SimpleLocation)
// are defined as you provided.

struct MoodPostCard: View {
    let post: FeedItem // Using your defined FeedItem struct
    @State private var isLiked = false // Local state for UI, ideally fetch/sync real like state
    // let initialLikeCount: Int // Would come from post.likesCount
    // let initialCommentCount: Int // Would come from post.commentsCount

    @State private var displayUsername: String = ""
    @State private var isLoadingUsername: Bool = false
    @State private var usernameFetchFailed: Bool = false
    
    // Helper to format the timestamp string into a relative date string
    private func formatRelativeTimestamp(from timestampString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        // Ensure the formatter can handle various ISO8601 fractional seconds precision
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: timestampString) else {
            // Fallback for invalid timestamp format
            // Try parsing without fractional seconds if the first attempt fails
            isoFormatter.formatOptions = [.withInternetDateTime]
            guard let dateWithoutFractions = isoFormatter.date(from: timestampString) else {
                // If still fails, provide a generic fallback
                return "Recently"
            }
            // Use the date parsed without fractions if that succeeded
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated // e.g., "1 hr. ago", "2 days ago", "In 3 min."
            formatter.dateTimeStyle = .named // e.g., "yesterday", "today", "now"
            return formatter.localizedString(for: dateWithoutFractions, relativeTo: Date())
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated // e.g., "1 hr. ago", "2 days ago", "now"
        formatter.dateTimeStyle = .named   // This provides "yesterday", "today", etc.
                                           // For "now" or very recent times, it's quite effective.
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header Section
            HStack(spacing: 10) {
                // Username and Timestamp
                VStack(alignment: .leading, spacing: 2) {
                    if isLoadingUsername {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(height: 18)
                    } else {
                        Text(displayUsername)
                            .font(.custom("Georgia", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(usernameFetchFailed ? .gray.opacity(0.7) : .white)
                            .lineLimit(1).truncationMode(.tail)
                    }
                    
                    Text(formatRelativeTimestamp(from: post.timestamp))
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Emotion Display
                HStack(spacing: 6) {
                    Circle()
                        .fill(post.emotion.color ?? Color.gray) // Uses SimpleEmotion.color
                        .frame(width: 10, height: 10)
                    
                    Text(post.emotion.name) // Uses SimpleEmotion.name
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(post.emotion.color ?? .white)
                }
            }
            
            // MARK: - Post Content Text (Reason)
            if let reasonText = post.content, !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(reasonText)
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // MARK: - Location and People Info
            let hasContent = post.content != nil && !(post.content?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let hasLocation = post.location?.name != nil && !(post.location?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            let hasPeople = post.people != nil && !(post.people?.isEmpty ?? true)

            if hasLocation || hasPeople { // Only show this VStack if there's location or people
                VStack(alignment: .leading, spacing: 5) {
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
                .padding(.top, hasContent ? 8 : 0) // Add top padding only if there's main content above
            }


            // MARK: - Interaction Buttons
            HStack(spacing: 25) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                        // TODO: Call backend to update like status and fetch new like count
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
                        // Displaying likesCount from FeedItem + local optimistic update
                        Text("\(post.likesCount + (isLiked && !(post.isLikedByCurrentUser ?? false) ? 1 : (!isLiked && (post.isLikedByCurrentUser ?? false) ? -1 : 0)))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .animation(nil, value: isLiked)
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
                        Text("\(post.commentsCount)") // Displaying commentsCount from FeedItem
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    // TODO: Share post
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, (hasLocation || hasPeople || hasContent) ? 8 : 0) // Add padding if there's any content above buttons
        }
        .padding(16)
        .background(Color.black.opacity(0.25))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear(){
            // Initialize local like state if your FeedItem has this info
            // self.isLiked = post.isLikedByCurrentUser ?? false
            loadUsername()
        }
    }
    
    private func loadUsername() {
        isLoadingUsername = true
        usernameFetchFailed = false
        // Use a more generic placeholder while loading if post.isAnonymous could be true
        // For now, assuming fetchUsername will handle anonymous display if needed.
        displayUsername = "Loading..."
        
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
}

// Add this to your FeedItem if you track current user's like state
extension FeedItem {
    var isLikedByCurrentUser: Bool? { // This is an example, add actual logic/property
        nil // Or true/false based on actual data
    }
}

// MARK: - Preview
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
