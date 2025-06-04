import SwiftUI

struct ProfileOverviewView: View {
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
            } else if let error = contentLoadingError, summary == nil && posts.isEmpty {
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
                    ProfileSummarySectionView(
                        summary: self.summary,
                        isLoading: self.isLoadingContent && self.summary == nil,
                        loadingError: self.summary == nil ? self.contentLoadingError : nil
                    )
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
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if !posts.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        MoodPostCard(post: post.toFeedItem(), openDetailAction: {})
                    }
                }
            } else if contentLoadingError == nil && !isLoadingContent {
                Text("No recent activity to display.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if isLoadingContent && posts.isEmpty {
                ProgressView("Loading posts...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        } else if isRefresh {
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
                if self.summary == nil && self.posts.isEmpty {
                    self.isLoadingContent = false
                    self.contentLoadingError = "Failed to load profile data. Please try again."
                    print("ProfileOverviewView: Error loading content - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchSummaryData() async throws -> UserSummary {
        try await Task.sleep(for: .milliseconds(50))
        return try await withCheckedThrowingContinuation { continuation in
            ProfileService.fetchSummary { result in
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
            MoodPostService.fetchMoodPosts(endpoint: "/api/checkin/\(userId)") { result in
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
