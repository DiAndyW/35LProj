//
//  FriendsService.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/22/25.
//

import SwiftUI

class FriendsService {
    func fetchFriends() async throws -> [Friend] {
        //the actual api call is not implemented yet
//        try await
        
        //return hard coded data atm
        let friends = [
            Friend(
                displayName: "Alice Johnson",
                avatarImageName: "person.crop.circle.fill",
                currentMood: Mood(name: "Happy", imageName: "face.smiling", color: .yellow)
            ),
            Friend(
                displayName: "Bob Smith",
                avatarImageName: "person.crop.circle.fill",
                currentMood: Mood(name: "Excited", imageName: "star.fill", color: .orange)
            ),
            Friend(
                displayName: "Emma Davis",
                avatarImageName: "person.crop.circle.fill",
                currentMood: Mood(name: "Calm", imageName: "leaf.fill", color: .green)
            ),
            Friend(
                displayName: "Mike Wilson",
                avatarImageName: "person.crop.circle.fill",
                currentMood: Mood(name: "Tired", imageName: "moon.fill", color: .blue)
            ),
            Friend(
                displayName: "Sarah Brown",
                avatarImageName: "person.crop.circle.fill",
                currentMood: Mood(name: "Focused", imageName: "target", color: .purple)
            )
        ]
        
        return friends
    }
}
