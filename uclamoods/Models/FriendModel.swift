//
//  FriendModel.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/22/25.
//

import SwiftUI

//temporary
struct Friend: Identifiable {
    let id = UUID()
    let displayName: String
    let avatarImageName: String //temporary, this uses the default swift avatar
    let currentMood: Mood
}
