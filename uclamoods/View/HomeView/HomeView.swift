// Enhanced HomeFeedView.swift with pagination support

import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    // Pagination state
    @State private var posts: [MoodPost] = []
    @State private var isInitialLoading: Bool = false
    @State private var isLoadingMore: Bool = false
    @State private var hasMorePosts: Bool = true
    @State private var currentSkip: Int = 0
    @State private var errorMessage: String?
    
    // Detail view state
    @State private var selectedPostForDetail: FeedItem?
    @State private var showDetailViewAnimated: Bool = false
    
    // Constants
    private let pageSize = 20
    private let sortMethod = "timestamp" // or "hottest"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    headerSection
                    
                    if isInitialLoading && posts.isEmpty {
                        initialLoadingView
                    } else {
                        feedContentView(geometry: geometry)
                    }
                }
                .blur(radius: showDetailViewAnimated ? 15 : 0)
                .disabled(showDetailViewAnimated)
                
                // Detail view overlay
                if showDetailViewAnimated {
                    detailViewOverlay(geometry: geometry)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear {
                if posts.isEmpty {
                    loadInitialPosts()
                }
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Morii")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { router.navigateToMoodFlow() }) {
                    Image(systemName: "plus.bubble")
                        .font(.system(size: 22))
                        .foregroundColor(.pink)
                }
            }
            Text("How's everyone feeling?")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Loading Views
    @ViewBuilder
    private var initialLoadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading feed...")
                .foregroundColor(.white)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        } else if !hasMorePosts {
            Text("You've reached the end!")
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding()
        }
    }
    
    // MARK: - Feed Content
    @ViewBuilder
    private func feedContentView(geometry: GeometryProxy) -> some View {
        if posts.isEmpty && !isInitialLoading {
            emptyStateContent(geometry: geometry)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { moodPostData in
                        let feedItem = moodPostData.toFeedItem()
                        MoodPostCard(
                            post: feedItem,
                            openDetailAction: {
                                presentDetailView(for: feedItem)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            presentDetailView(for: feedItem)
                        }
                        .onAppear {
                            // Trigger load more when near the end
                            if moodPostData.id == posts.last?.id {
                                loadMorePostsIfNeeded()
                            }
                        }
                    }
                    
                    // Load more indicator
                    loadMoreView
                }
                .padding(.horizontal, 16)
                .padding(.bottom, max(100, geometry.safeAreaInsets.bottom) + 70)
            }
            .refreshable {
                await refreshPosts()
            }
        }
        
        // Error handling
        if let error = errorMessage {
            VStack {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
                Button("Retry") {
                    if posts.isEmpty {
                        loadInitialPosts()
                    } else {
                        loadMorePostsIfNeeded()
                    }
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.circle")
                .font(.system(size: 60))
                .foregroundColor(.pink.opacity(0.6))
            VStack(spacing: 8) {
                Text("Welcome to your mood feed!")
                    .font(.custom("Georgia", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("Check in with your mood to see posts from friends and the community.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button(action: { router.navigateToMoodFlow() }) {
                Text("Make your first check-in")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.pink.opacity(0.8)))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, geometry.size.height * 0.1)
    }
    
    // MARK: - Detail View Overlay
    @ViewBuilder
    private func detailViewOverlay(geometry: GeometryProxy) -> some View {
        Color.black.opacity(0.4)
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity)
            .onTapGesture { dismissDetailView() }
        
        if let postToShow = selectedPostForDetail {
            MoodPostDetailView(
                post: postToShow,
                onDismiss: dismissDetailView
            )
            .environmentObject(userDataProvider)
            .environmentObject(router)
            .frame(
                width: geometry.size.width * 0.95,
                height: max(
                    geometry.size.height * 0.5,
                    min(geometry.size.height * 0.90, 700)
                )
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
        }
    }
    
    // MARK: - Pagination Logic
    private func loadInitialPosts() {
        guard !isInitialLoading else { return }
        
        isInitialLoading = true
        errorMessage = nil
        currentSkip = 0
        hasMorePosts = true
        
        Task {
            let result = await fetchPosts(skip: 0, limit: pageSize)
            await MainActor.run {
                isInitialLoading = false
                switch result {
                case .success(let newPosts):
                    self.posts = newPosts
                    self.hasMorePosts = newPosts.count == pageSize
                    self.currentSkip = newPosts.count
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadMorePostsIfNeeded() {
        guard !isLoadingMore && hasMorePosts && !isInitialLoading else { return }
        
        isLoadingMore = true
        errorMessage = nil
        
        Task {
            let result = await fetchPosts(skip: currentSkip, limit: pageSize)
            await MainActor.run {
                isLoadingMore = false
                switch result {
                case .success(let newPosts):
                    if newPosts.isEmpty {
                        self.hasMorePosts = false
                    } else {
                        self.posts.append(contentsOf: newPosts)
                        self.currentSkip += newPosts.count
                        self.hasMorePosts = newPosts.count == pageSize
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func refreshPosts() async {
        let result = await fetchPosts(skip: 0, limit: pageSize)
        await MainActor.run {
            switch result {
            case .success(let newPosts):
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.posts = newPosts
                    self.currentSkip = newPosts.count
                    self.hasMorePosts = newPosts.count == pageSize
                    self.errorMessage = nil
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func fetchPosts(skip: Int, limit: Int) async -> Result<[MoodPost], MoodPostServiceError> {
        await withCheckedContinuation { continuation in
            MoodPostService.fetchMoodPosts(
                skip: skip,
                limit: limit,
                sort: sortMethod
            ) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Detail View Management
    private func dismissDetailView() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showDetailViewAnimated = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectedPostForDetail = nil
        }
        if router.tabWithActiveDetailView == .home {
            router.tabWithActiveDetailView = nil
        }
    }
    
    private func presentDetailView(for feedItem: FeedItem) {
        selectedPostForDetail = feedItem
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showDetailViewAnimated = true
        }
        router.tabWithActiveDetailView = .home
    }
}
