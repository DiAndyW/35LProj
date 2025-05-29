//
//  MoodPostCard.swift
//  uclamoods
//
//  Created by Yang Gao on 5/28/25.
//
import SwiftUI

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
