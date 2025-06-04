//
//  ActivityCard.swift
//  uclamoods
//
//  Created by David Sun on 6/1/25.
//
import Foundation
import SwiftUI

struct ActivityCard: View {
    let post: FeedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(post.emotion.color ?? Color.gray)
                    .frame(width: 28, height: 28)
                    
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.emotion.name)
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let timestampParts = DateFormatterUtility.formatTimestampParts(timestampString: post.timestamp) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timestampParts.relativeDate)
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        Text(timestampParts.absoluteDate)
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            if let contentText = post.content, !contentText.isEmpty { // Safely unwrap and check
                Text(contentText)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(nil) // Allows multiple lines
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

/*
struct ActivityCard_Previews: PreviewProvider {
    static var sampleFeedItem: FeedItem {
        // Create a sample SimpleEmotion
        let sampleEmotion = SimpleEmotion(
            name: "Happy",
            pleasantness: 0.8,
            intensity: 0.7,
            clarity: 0.9,
            control: 0.75,
            color: .yellow
        )
        
        // Create a sample SimpleLocation (optional)
        let sampleLocation = SimpleLocation(name: "Westwood Village")
        
        // Create a dummy date string
        let dummyDateString: String
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dummyDateString = formatter.string(from: Date())
        
        // Create and return a sample FeedItem
        return FeedItem(
            id: "samplePost123",
            userId: "userXYZ",
            emotion: sampleEmotion,
            content: "Having a great day exploring the area and enjoying the sunshine!",
            people: ["Alice", "Bob"],
            activities: ["Exploring", "Eating"],
            location: sampleLocation,
            timestamp: dummyDateString,
            likesCount: 0,
            commentsCount: 0
        )
    }
    
    static var previews: some View {
        // Display the ActivityCard with the sample data
        ActivityCard(post: sampleFeedItem)
            .padding() // Add some padding around the card in the preview canvas
            .previewLayout(.sizeThatFits) // Make the preview canvas fit the content
    }
}
*/
