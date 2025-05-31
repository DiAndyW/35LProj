//
//  MoodPostCard.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
import SwiftUI
import Foundation

struct DateFormatterUtility {
    
    // Static formatters (reused for performance)
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let simplerISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
    
    private static let absoluteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, YYYY"
        return formatter
    }()
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .beginningOfSentence
        return formatter
    }()
    
    static func formatTimestampParts(timestampString: String) -> (absoluteDate: String, relativeDate: String)? {
        guard let date = parseDate(from: timestampString) else {
            return nil
        }
        
        let absoluteDateString = absoluteDateFormatter.string(from: date)
        let relativeDateString = relativeFormatter.localizedString(for: date, relativeTo: Date())
        
        return (absoluteDate: absoluteDateString, relativeDate: relativeDateString)
    }
    
    private static func parseDate(from timestampString: String) -> Date? {
        if let date = isoFormatter.date(from: timestampString) {
            return date
        }
        if let date = simplerISOFormatter.date(from: timestampString) {
            return date
        }
        print("DateFormatterUtility: Failed to parse date string: \(timestampString)")
        return nil
    }
}


struct MoodPostCard: View {
    let post: FeedItem
    @State private var isLiked = false
    
    @State private var displayUsername: String = ""
    @State private var isLoadingUsername: Bool = false
    @State private var usernameFetchFailed: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    if isLoadingUsername {
                        ProgressView()
                            .scaleEffect(0.7) // Make it a bit smaller
                            .frame(height: 18) // Match approx Text height
                    } else {
                        Text(displayUsername)
                            .font(.custom("Georgia", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(usernameFetchFailed ? .gray.opacity(0.7) : .white)
                            .lineLimit(1).truncationMode(.tail)
                    }
                    
                    if let timestampParts = DateFormatterUtility.formatTimestampParts(timestampString: post.timestamp) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(timestampParts.relativeDate)
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                            Text(timestampParts.absoluteDate)
                                .font(.custom("Georgia", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(post.emotion.color ?? Color.gray) // Provide default if color is nil
                        .frame(width: 12, height: 12)
                    
                    Text(post.emotion.name)
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(post.emotion.color ?? .white) // Provide default if color is nil
                }
            }
            
            // Post content (using post.content, which is String?)
            if let contentText = post.content, !contentText.isEmpty { // Safely unwrap and check
                Text(contentText)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(nil) // Allows multiple lines
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
                        Text("\((0) + (isLiked ? 1 : 0))") // Placeholder for likes
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
                        Text("\(0)") // Placeholder for comments
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
        .onAppear(){
            loadUsername()
        }
    }
    
    private func loadUsername() {
        isLoadingUsername = true
        usernameFetchFailed = false
        displayUsername = "Loading user..."
        
        fetchUsername(for: post.userId) { result in
            isLoadingUsername = false
            switch result {
                case .success(let fetchedName):
                    self.displayUsername = fetchedName
                case .failure(let error):
                    print("Failed to fetch username for \(post.userId): \(error.localizedDescription)")
                    self.displayUsername = post.userId
                    self.usernameFetchFailed = true
            }
        }
    }
}
