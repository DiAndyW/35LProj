import SwiftUI

struct ProfileOverviewView: View {
    // Data states
    @State private var posts: [MoodPost] = []
    @State private var summary: UserSummary? = nil
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    @State private var isLoadingContent: Bool = true
    @State private var contentLoadingError: String? = nil
    
    let refreshID: UUID
    
    var body: some View {
        Group {
            if isLoadingContent && summary == nil && posts.isEmpty {
                ProgressView("Loading overview...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 50)
            } else if let error = contentLoadingError {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("Failed to load overview")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadContent(isRefresh: true)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    summarySection
                    postsSection
                }
                .padding(.vertical)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .center)))
            }
        }
        .task(id: refreshID) {
            await loadContent(isRefresh: summary != nil || !posts.isEmpty)
        }
    }
    
    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if let currentSummaryData = summary?.data {
                let weeklySummary = currentSummaryData.weeklySummary
                let avgPleasantness = weeklySummary.averageMoodForWeek.averageAttributes.pleasantness
                let avgIntensity = weeklySummary.averageMoodForWeek.averageAttributes.intensity
                let avgControl = weeklySummary.averageMoodForWeek.averageAttributes.control
                let avgClarity = weeklySummary.averageMoodForWeek.averageAttributes.clarity
                let averageEmotion = Emotion(
                    name: weeklySummary.averageMoodForWeek.topEmotion ?? "Average",
                    color: ColorData.calculateMoodColor(pleasantness: avgPleasantness, intensity: avgIntensity) ?? .gray,
                    description: "Average mood for the week.",
                    pleasantness: avgPleasantness,
                    intensity: avgIntensity,
                    control: avgControl,
                    clarity: avgClarity
                )
                VStack(spacing: 0) {
                    HStack {
                        Text("Average Attributes")
                            .font(.custom("Georgia", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    
                    EmotionRadarChartView(emotion: averageEmotion)
                        .offset(y: -10)
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(averageEmotion.color.opacity(0.6), lineWidth: 2)
                )
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    WeekStatCard(title: "Top Emotion", value: weeklySummary.weeklyTopMood?.name ?? "N/A")
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EmotionDataProvider.getEmotion(byName: weeklySummary.weeklyTopMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                        )
                    
                    WeekStatCard(title: "Check-ins", value: "\(weeklySummary.weeklyCheckinsCount)")
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EmotionDataProvider.getEmotion(byName: weeklySummary.weeklyTopMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                        )
                }
            } else if contentLoadingError == nil && !isLoadingContent {
                Text("No summary data available for this week.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if isLoadingContent {
                ProgressView("Loading weekly summary...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if !posts.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        ProfilePostCard(post: post.toFeedItem(), openDetailAction: {})
                    }
                }
            } else if contentLoadingError == nil && !isLoadingContent {
                Text("No recent activity to display.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
    }
    
    private func loadContent(isRefresh: Bool = false) async {
        if !isRefresh || (summary == nil && posts.isEmpty) {
            await MainActor.run {
                isLoadingContent = true
                contentLoadingError = nil
            }
        } else {
            await MainActor.run {
                isLoadingContent = true
                contentLoadingError = nil
            }
        }
        
        print("ProfileOverviewView: Loading content (isRefresh: \(isRefresh))...")
        
        do {
            async let summaryDataResult = fetchSummaryData()
            async let postsDataResult = fetchPostsData()
            
            let fetchedSummary = try await summaryDataResult
            let fetchedPosts = try await postsDataResult
            
            await MainActor.run {
                self.summary = fetchedSummary
                self.posts = fetchedPosts
                self.contentLoadingError = nil
                self.isLoadingContent = false
                print("ProfileOverviewView: Content loaded successfully.")
            }
        } catch {
            await MainActor.run {
                self.contentLoadingError = "No data available!"
                self.isLoadingContent = false
                print("ProfileOverviewView: Error loading content - \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchSummaryData() async throws -> UserSummary {
        try await Task.sleep(for: .milliseconds(50))
        return try await withCheckedThrowingContinuation { continuation in
            ProfileService.fetchSummary { result in //
                switch result {
                    case .success(let summary):
                        continuation.resume(returning: summary)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchPostsData() async throws -> [MoodPost] {
        try await Task.sleep(for: .milliseconds(50))
        guard let userId = userDataProvider.currentUser?.id, !userId.isEmpty, userId != "000" else {
            throw NSError(domain: "DataFetching", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid or missing user ID for fetching posts."])
        }
        return try await withCheckedThrowingContinuation { continuation in
            MoodPostService.fetchMoodPosts(endpoint: "/api/checkin/\(userId)") { result in //
                switch result {
                    case .success(let posts):
                        continuation.resume(returning: posts)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
}
