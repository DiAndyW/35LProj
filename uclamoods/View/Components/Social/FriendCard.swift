//
//  FriendCard.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/22/25.
//

import SwiftUI

struct FriendCard: View {
    let friend: Friend
    
    var body: some View {
        HStack(spacing: 16) {
            //avatar
            Image(systemName: friend.avatarImageName)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                )
            
            //friend current status
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: friend.currentMood.imageName)
                        .font(.system(size: 16))
                        .foregroundColor(friend.currentMood.color)
                    
                    Text("Feeling \(friend.currentMood.name)")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        //rectangular background separating each friend
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
