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
                
                if let userdata = summary {
                    let avgpleasantness = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.pleasantness
                    let avgintensity = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.intensity
                    let avgcontrol = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.control
                    let avgclarity = userdata.data.weeklySummary.averageMoodForWeek.averageAttributes.clarity

                    let averageEmotion = Emotion(name: "Enraged",
                                                 color: ColorData.calculateMoodColor(pleasantness: avgpleasantness, intensity: avgintensity) ?? .gray,
                                                 description: "",
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
                        WeekStatCard(title: "Top Emotion", value: userdata.data.weeklySummary.weeklyTopMood?.name ?? "No Data")
                        WeekStatCard(title: "Check-ins", value: "\(userdata.data.weeklySummary.weeklyCheckinsCount)")
                    }
                }else{
                    Text("No activity yet!")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.white)
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
