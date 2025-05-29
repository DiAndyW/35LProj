//
//  MoodPost.swift
//  uclamoods
//
//  Created by Yang Gao on 5/28/25.
//


import SwiftUI

// MARK: - Missing Data Models

struct MoodPost: Identifiable {
    let id = UUID()
    let username: String
    let timeAgo: String
    let emotion: String
    let emotionColor: Color
    let content: String
    let likes: Int
    let comments: Int
    
    static let samplePosts = [
        MoodPost(
            username: "Alex Chen", 
            timeAgo: "2h", 
            emotion: "Happy", 
            emotionColor: .yellow, 
            content: "Just finished my morning run and feeling amazing! The sunset was incredible today. 🌅", 
            likes: 12, 
            comments: 3
        ),
        MoodPost(
            username: "Jordan Smith", 
            timeAgo: "4h", 
            emotion: "Excited", 
            emotionColor: .orange, 
            content: "Got accepted into my dream graduate program! Can't believe it's finally happening!", 
            likes: 28, 
            comments: 7
        ),
        MoodPost(
            username: "Sam Rodriguez", 
            timeAgo: "6h", 
            emotion: "Calm", 
            emotionColor: .blue, 
            content: "Meditation session in the park. Sometimes you just need to pause and breathe.", 
            likes: 15, 
            comments: 2
        ),
        MoodPost(
            username: "Taylor Kim", 
            timeAgo: "8h", 
            emotion: "Grateful", 
            emotionColor: .green, 
            content: "Lunch with my grandmother today. Her stories always put life in perspective. ❤️", 
            likes: 22, 
            comments: 5
        ),
        MoodPost(
            username: "Morgan Lee", 
            timeAgo: "12h", 
            emotion: "Motivated", 
            emotionColor: .purple, 
            content: "Starting a new art project tonight. Time to get creative!", 
            likes: 9, 
            comments: 1
        ),
        MoodPost(
            username: "Riley Johnson", 
            timeAgo: "1d", 
            emotion: "Peaceful", 
            emotionColor: .mint, 
            content: "Beach walk at sunrise. Nothing beats the sound of waves to start the day.", 
            likes: 18, 
            comments: 4
        ),
        MoodPost(
            username: "Casey Park", 
            timeAgo: "1d", 
            emotion: "Inspired", 
            emotionColor: .pink, 
            content: "Just watched an incredible documentary about ocean conservation. Time to make some changes!", 
            likes: 33, 
            comments: 9
        )
    ]
}

struct UserStats {
    let totalCheckIns: Int
    let currentStreak: Int
    let topEmotion: String
    let weeklyCheckIns: Int
    let averageEnergy: String
    let longestStreak: Int
    
    static let sample = UserStats(
        totalCheckIns: 127,
        currentStreak: 8,
        topEmotion: "Happy",
        weeklyCheckIns: 5,
        averageEnergy: "High",
        longestStreak: 15
    )
}

// MARK: - Missing Helper Components

struct MoodPostCard: View {
    let post: MoodPost
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.custom("Georgia", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(post.timeAgo)
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Mood indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(post.emotionColor)
                        .frame(width: 12, height: 12)
                    
                    Text(post.emotion)
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(post.emotionColor)
                }
            }
            
            // Post content
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(nil)
            }
            
            // Interaction buttons
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.prepare()
                    impactFeedback.impactOccurred()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isLiked ? .red : .white.opacity(0.6))
                            .scaleEffect(isLiked ? 1.2 : 1.0)
                        
                        Text("\(post.likes + (isLiked ? 1 : 0))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Button(action: {
                    // TODO: Open comments
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(post.comments)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Button(action: {
                    // TODO: Share post
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct RecentActivityItem: View {
    let emotion: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("Felt \(emotion)")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(time)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}

struct WeekStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.custom("Georgia", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.pink)
            
            Text(title)
                .font(.custom("Georgia", size: 14))
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    
    init(icon: String, title: String, subtitle: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.pink)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
