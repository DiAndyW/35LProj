//
//  ProfileOverviewView.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
import SwiftUI

struct ProfileOverviewView: View {
    @State private var posts: [MoodPost] = []
    @State private var summary: UserSummary? = nil
    @StateObject private var userDataProvider = UserDataProvider.shared
    @State private var isLoading: Bool = false
    
    let refreshID: UUID
    
    var body: some View {
        mainContentView
            .onAppear {
                if summary == nil && posts.isEmpty {
                    Task {
                        await loadInitialData()
                    }
                }
            }
            .onChange(of: refreshID) {
                Task {
                    print("ProfileOverviewView: refreshID changed, calling refreshData()")
                    await refreshData(isPullToRefresh: true)
                }
            }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if isLoading && summary == nil {
            VStack {
                Spacer()
                ProgressView("Loading overview...")
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
        } else if let userdata = summary {
            VStack(spacing: 20) {
                // This week summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("This Week")
                        .font(.custom("Georgia", size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    let avgpleasantness = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.pleasantness
                    let avgintensity = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.intensity
                    let avgcontrol = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.control
                    let avgclarity = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.clarity
                    
                    let averageEmotion = Emotion(name: userdata.data.weeklySummary.averageMoodForWeek.topEmotion ?? "Average",
                                                 color: ColorData.calculateMoodColor(pleasantness: avgpleasantness, intensity: avgintensity) ?? .gray,
                                                 description: "Average mood for the week.",
                                                 pleasantness: avgpleasantness, intensity: avgintensity, control: avgcontrol, clarity: avgclarity)
                    
                    EmotionRadarChartView(emotion: averageEmotion)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        WeekStatCard(title: "Top Emotion", value: userdata.data.weeklySummary.weeklyTopMood?.name ?? "N/A")
                        WeekStatCard(title: "Check-ins", value: "\(userdata.data.weeklySummary.weeklyCheckinsCount)")
                    }
                }
                
                // Recent activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.custom("Georgia", size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if posts.isEmpty {
                        if !isLoading { // Avoid showing "No activity" while a refresh might be loading posts
                            Text("No activity yet!")
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        }
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                let feed = post.toFeedItem()
                                ActivityCard(post: feed)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        } else { // summary is nil and not isLoading (e.g., error state or after failed load)
            VStack {
                Text("No summary data available. Pull to refresh.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 50)
            }
        }
    }
    
    private func refreshData(isPullToRefresh: Bool = false) async {
        print("ProfileOverviewView: Refreshing data...")
        async let summaryResult: () = loadSummaryAsync()
        async let feedResult: () = loadFeedAsync()
        
        _ = await summaryResult
        _ = await feedResult
        
        if !isPullToRefresh {
            await MainActor.run { isLoading = false }
        }
        print("ProfileOverviewView: Data refresh complete.")
    }
    
    private func loadInitialData() async {
        guard !isLoading else { return }
        await MainActor.run { isLoading = true }
        print("ProfileOverviewView: Loading initial data...")
        
        await refreshData(isPullToRefresh: false)
        
        await MainActor.run { isLoading = false }
        print("ProfileOverviewView: Initial data load complete.")
    }
    
    @MainActor
    private func loadSummaryAsync() async {
        return await withCheckedContinuation { continuation in
            ProfileService.fetchSummary() { result in
                switch result {
                    case .success(let fetchedSummary):
                        self.summary = fetchedSummary
                        print("ProfileOverviewView: Successfully fetched summary (async).")
                    case .failure(let error):
                        print("ProfileOverviewView: Error fetching summary (async): \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }
    
    @MainActor
    private func loadFeedAsync() async {
        guard let userId = userDataProvider.currentUser?.id, !userId.isEmpty, userId != "000" else {
            print("ProfileOverviewView: Error fetching posts (async): Invalid or missing user ID.")
            self.posts = []
            return
        }
        
        return await withCheckedContinuation { continuation in
            MoodPostService.fetchMoodPosts(endpoint: "/api/checkin/\(userId)") { result in
                switch result {
                    case .success(let fetchedPosts):
                        self.posts = fetchedPosts
                        print("ProfileOverviewView: Successfully fetched \(fetchedPosts.count) posts (async).")
                    case .failure(let error):
                        print("ProfileOverviewView: Error fetching posts (async): \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }
}
