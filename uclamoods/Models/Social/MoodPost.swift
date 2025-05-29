//
//  MoodPost.swift
//  uclamoods
//
//  Created by Yang Gao on 5/28/25.
//
import SwiftUI

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
