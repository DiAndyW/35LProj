import SwiftUI

// MARK: - Home Feed View (Twitter-like combined feed)
struct HomeFeedView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var posts: [MoodPost] = []
    @State private var isLoading = false
    @State private var showingCompose = false
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with app branding
                VStack(spacing: 8) {
                    HStack {
                        Text("Morii")
                            .font(.custom("Georgia", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Quick check-in shortcut button
                        Button(action: {
                            router.navigateToMoodFlow()
                        }) {
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
                
                // Feed content
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading feed...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                } else if posts.isEmpty {
                    // Empty state
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
                        
                        Button(action: {
                            router.navigateToMoodFlow()
                        }) {
                            Text("Make your first check-in")
                                .font(.custom("Georgia", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(Color.pink.opacity(0.8))
                                )
                        }
                        
                        Spacer()
                    }
                } else {
                    // Posts feed
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                MoodPostCard(post: post)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, max(100, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) + 70)
                    }
                }
            }
        }
        .onAppear {
            loadFeed()
        }
        .refreshable {
            await refreshFeed()
        }
    }
    
    private func loadFeed() {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Load sample posts for now
            posts = MoodPost.samplePosts
            isLoading = false
        }
    }
    
    private func refreshFeed() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        posts = MoodPost.samplePosts.shuffled()
    }
}
