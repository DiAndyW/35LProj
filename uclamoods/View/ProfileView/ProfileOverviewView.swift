import SwiftUI

struct ProfileOverviewView: View {
    @State private var posts: [MoodPost] = []
    @State private var summary: UserSummary? = nil
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    @State private var isInitialLoading: Bool = true
    @State private var contentLoadingError: String? = nil
    
    @State private var isLoadingMore: Bool = false
    @State private var hasMorePosts: Bool = true
    @State private var currentSkip: Int = 0
    private let pageSize: Int = 10
    
    let refreshID: UUID
    let onSelectPost: (FeedItem) -> Void
    
    var body: some View {
        Group {
            if isInitialLoading && posts.isEmpty && summary == nil {
                ProgressView("Loading overview...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 50)
            } else if let error = contentLoadingError, posts.isEmpty && summary == nil {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("Failed to load profile data.")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadInitialContent()
                        }
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    ProfileSummarySectionView(
                        summary: self.summary,
                        isLoading: self.isInitialLoading && self.summary == nil,
                        loadingError: self.summary == nil ? self.contentLoadingError : nil
                    )
                    Divider().background(Color.white.opacity(0.5))
                    postsSection
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .center)))
            }
        }
        .task(id: refreshID) {
            await loadInitialContent(isRefresh: !isInitialLoading)
        }
    }
    
    @ViewBuilder
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if posts.isEmpty && !isInitialLoading && !isLoadingMore && contentLoadingError == nil {
                Text("No recent activity to display.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        let feedItem = post.toFeedItem()
                        ProfilePostCard(
                            post: feedItem,
                            openDetailAction: {
                                onSelectPost(feedItem)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectPost(feedItem)
                        }
                        .onAppear {
                            if post.id == posts.last?.id {
                                loadMorePostsIfNeeded()
                            }
                        }
                    }
                    loadMoreView
                }
            }
        }
    }
    
    @ViewBuilder
    private var loadMoreView: some View {
        if isLoadingMore {
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("Loading more posts...")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        } else if !hasMorePosts && !posts.isEmpty {
            Text("You've reached the end!")
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding()
        }
    }
    
    private func loadInitialContent(isRefresh: Bool = false) async {
        await MainActor.run {
            if isRefresh {
                self.isInitialLoading = true
                self.currentSkip = 0
                self.hasMorePosts = true
            } else {
                self.isInitialLoading = true
                self.contentLoadingError = nil
                self.currentSkip = 0
                self.hasMorePosts = true
            }
        }
        
        print("ProfileOverviewView: Loading initial content (isRefresh: \(isRefresh))...")
        
        async let summaryTask: () = fetchSummaryDataAsync()
        async let postsTask: () = fetchAndSetPosts(skip: 0, isInitialLoadOrRefresh: true)
        
        _ = await [summaryTask, postsTask]
        
        await MainActor.run {
            self.isInitialLoading = false
        }
    }
    
    private func loadMorePostsIfNeeded() {
        guard !isLoadingMore && hasMorePosts && !isInitialLoading else { return }
        
        Task {
            await MainActor.run { isLoadingMore = true }
            await fetchAndSetPosts(skip: currentSkip, isInitialLoadOrRefresh: false)
            await MainActor.run { isLoadingMore = false }
        }
    }
    
    private func fetchSummaryDataAsync() async {
        if summary == nil || (isInitialLoading && currentSkip == 0) {
            do {
                let fetchedSummary = try await fetchSummaryData()
                await MainActor.run {
                    self.summary = fetchedSummary
                }
            } catch {
                await MainActor.run {
                    if self.posts.isEmpty {
                        self.contentLoadingError = "Failed to load profile summary. \(error.localizedDescription)"
                    }
                    print("ProfileOverviewView: Error loading summary - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchAndSetPosts(skip: Int, isInitialLoadOrRefresh: Bool) async {
        guard let userId = userDataProvider.currentUser?.id, !userId.isEmpty, userId != "000" else {
            await MainActor.run {
                self.contentLoadingError = "Invalid or missing user ID for fetching posts."
                if isInitialLoadOrRefresh { self.isInitialLoading = false } else { self.isLoadingMore = false }
                self.hasMorePosts = false
            }
            return
        }
        
        print("ProfileOverviewView: Fetching posts for userId: \(userId), skip: \(skip), limit: \(pageSize)")
        
        MoodPostService.fetchMoodPosts(endpoint: "/api/checkin/\(userId)", skip: skip, limit: pageSize) { result in
            DispatchQueue.main.async {
                if isInitialLoadOrRefresh {
                    self.isInitialLoading = false
                    if skip == 0 { self.posts.removeAll() }
                } else {
                    self.isLoadingMore = false
                }
                
                switch result {
                    case .success(let (newPosts, paginationInfo)):
                        if isInitialLoadOrRefresh {
                            self.posts = newPosts
                        } else {
                            let existingIDs = Set(self.posts.map { $0.id })
                            let uniqueNewPosts = newPosts.filter { !existingIDs.contains($0.id) }
                            self.posts.append(contentsOf: uniqueNewPosts)
                        }
                        self.currentSkip = self.posts.count
                        
                        if let pagination = paginationInfo {
                            self.hasMorePosts = pagination.currentPage < pagination.totalPages
                            print("ProfileOverviewView: Posts loaded. CurrentPage: \(pagination.currentPage), TotalPages: \(pagination.totalPages), HasMore: \(self.hasMorePosts)")
                        } else {
                            self.hasMorePosts = newPosts.count == self.pageSize
                        }
                        
                        if !newPosts.isEmpty || self.summary != nil {
                            self.contentLoadingError = nil
                        }
                        print("ProfileOverviewView: Posts processed. New count: \(newPosts.count). Total: \(self.posts.count)")
                        
                    case .failure(let error):
                        if isInitialLoadOrRefresh && self.posts.isEmpty && self.summary == nil {
                            self.contentLoadingError = "Failed to load posts. \(error.localizedDescription)"
                        }
                        self.hasMorePosts = false
                        print("ProfileOverviewView: Error fetching posts - \(error.localizedDescription)")
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
}
