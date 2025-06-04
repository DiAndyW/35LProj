import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var posts: [MoodPost] = []
    @State private var isLoading: Bool = true
    @State private var selectedPostForDetail: FeedItem?
    @State private var showDetailViewAnimated: Bool = false
    
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    private func dismissDetailView() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.showDetailViewAnimated = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.selectedPostForDetail = nil
        }
    }
    
    private func presentDetailView(for feedItem: FeedItem) {
        self.selectedPostForDetail = feedItem
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.showDetailViewAnimated = true
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Morii")
                    .font(.custom("Georgia", size: 28)).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Button(action: { router.navigateToMoodFlow() }) {
                    Image(systemName: "plus.bubble")
                        .font(.system(size: 22)).foregroundColor(.pink)
                }
            }
            Text("How's everyone feeling?")
                .font(.custom("Georgia", size: 16)).foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 20)
    }
    
    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.circle").font(.system(size: 60)).foregroundColor(.pink.opacity(0.6))
            VStack(spacing: 8) {
                Text("Welcome to your mood feed!").font(.custom("Georgia", size: 20)).fontWeight(.semibold).foregroundColor(.white)
                Text("Check in with your mood to see posts from friends and the community.").font(.custom("Georgia", size: 16)).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Button(action: { router.navigateToMoodFlow() }) {
                Text("Make your first check-in").font(.custom("Georgia", size: 18)).fontWeight(.semibold).foregroundColor(.white).padding(.horizontal, 30).padding(.vertical, 15).background(Capsule().fill(Color.pink.opacity(0.8)))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    headerSection
                    
                    if isLoading && posts.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading feed...")
                                .foregroundColor(.white)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            if posts.isEmpty {
                                emptyStateContent
                                    .padding(.top, geometry.size.height * 0.2)
                            } else {
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
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, max(100, geometry.safeAreaInsets.bottom) + 70)
                            }
                        }
                        .refreshable {
                            await loadFeedData(isRefresh: true)
                        }
                    }
                }
                .blur(radius: showDetailViewAnimated ? 15 : 0)
                .disabled(showDetailViewAnimated)
                
                if showDetailViewAnimated {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture { dismissDetailView() }
                }
                
                if let postToShow = selectedPostForDetail, showDetailViewAnimated {
                    MoodPostDetailView(
                        post: postToShow,
                        onDismiss: dismissDetailView
                    )
                    .environmentObject(userDataProvider)
                    .environmentObject(router)
                    .frame(width: geometry.size.width * 0.95, height: max(geometry.size.height * 0.5, min(geometry.size.height * 0.90, 700)))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear {
                if posts.isEmpty {
                    Task { await loadFeedData(isRefresh: false) }
                } else {
                    isLoading = false
                }
                if !showDetailViewAnimated {
                    router.isDetailViewShowing = false
                }
            }
            .onChange(of: showDetailViewAnimated) { newValue in
                router.isDetailViewShowing = newValue
            }
            .onChange(of: router.selectedMainTab) { oldTab, newTab in
                if newTab != .home && self.showDetailViewAnimated {
                    print("HomeFeedView: Tab changed from .home to \(newTab), dismissing detail view.")
                    self.dismissDetailView()
                }
            }
        }
    }
    
    private func loadFeedData(isRefresh: Bool) async {
        if !isRefresh && posts.isEmpty {
            await MainActor.run { isLoading = true }
        }
        
        let result = await fetchPostsFromServer()
        
        await MainActor.run {
            if !isRefresh {
                isLoading = false
            }
            switch result {
                case .success(let fetchedPosts):
                    if isRefresh {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.posts = fetchedPosts
                        }
                    } else {
                        self.posts = fetchedPosts
                    }
                case .failure(let error):
                    print("Error fetching posts: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchPostsFromServer() async -> Result<[MoodPost], MoodPostServiceError> {
        await withCheckedContinuation { continuation in
            MoodPostService.fetchMoodPosts(endpoint: "/api/feed") { result in //
                continuation.resume(returning: result)
            }
        }
    }
}
