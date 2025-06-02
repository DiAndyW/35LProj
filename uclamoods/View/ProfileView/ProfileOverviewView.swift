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

    
    var body: some View {
        VStack(spacing: 20) {
            // This week summary
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if let summary = summary {
                    EmotionRadarChartView(emotion: EmotionDataProvider.highEnergyEmotions[0])
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        WeekStatCard(title: "Top Emotion", value: summary.data.weeklySummary.weeklyTopMood?.name ?? "No Data",
                                     subtitle: "\(summary.data.weeklySummary.weeklyTopMood?.count ?? 0)")
                        WeekStatCard(title: "Check-ins", value: "\(summary.data.weeklySummary.weeklyCheckinsCount)", subtitle: "This week")
                    }
                }
            }
            
            // Recent activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if posts.isEmpty {
                    Text("No activity yet!")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.white)
                }else{
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                let feed = post.toFeedItem()
                                ActivityCard(post: feed)
                            }
                        }
                    }
                }
            }
        }
        .onAppear(){
            loadFeed()
            loadSummary()
        }
        .refreshable {
            loadFeed()
        }
    }
    
    private func loadSummary(){
        ProfileService.fetchSummary(){ result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let fetchedSummary):
                        self.summary = fetchedSummary
                        print("Successfully fetched summary.")
                    case .failure(let error):
                        print("Error fetching summary: \(error)")
                        switch error {
                            case .invalidURL:
                                print("Error Detail: The URL was invalid.")
                            case .networkError(let underlyingError):
                                print("Error Detail: Network issue - \(underlyingError.localizedDescription)")
                            case .invalidResponse:
                                print("Error Detail: The server response was not a valid HTTP response.")
                            case .noData:
                                print("Error Detail: No data was returned from the server.")
                            case .decodingError(let underlyingError):
                                print("Error Detail: Failed to decode the JSON - \(underlyingError.localizedDescription)")
                            case .serverError(let statusCode, let message):
                                print("Error Detail: Server returned status \(statusCode) with message: \(message ?? "N/A")")
                        }
                }
            }
        }
    }
    
    private func loadFeed() {
        MoodPostService.fetchMoodPosts(endpoint: "/api/checkin/\(userDataProvider.currentUser?.id ?? "000")") { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let posts):
                        self.posts = posts
                        print("Successfully fetched \(posts.count) posts.")
                        for post in posts {
                            print("Post ID: \(post.id), Emotion: \(post.emotion.name)")
                        }
                    case .failure(let error):
                        print("Error fetching posts: \(error)")
                        switch error {
                            case .invalidURL:
                                print("Error Detail: The URL was invalid.")
                            case .networkError(let underlyingError):
                                print("Error Detail: Network issue - \(underlyingError.localizedDescription)")
                            case .invalidResponse:
                                print("Error Detail: The server response was not a valid HTTP response.")
                            case .noData:
                                print("Error Detail: No data was returned from the server.")
                            case .decodingError(let underlyingError):
                                print("Error Detail: Failed to decode the JSON - \(underlyingError.localizedDescription)")
                            case .serverError(let statusCode, let message):
                                print("Error Detail: Server returned status \(statusCode) with message: \(message ?? "N/A")")
                        }
                }
            }
        }
    }
}
