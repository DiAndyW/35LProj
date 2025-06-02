//
//  ProfileAnalyticsView.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
import SwiftUI

struct ProfileAnalyticsView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            // Placeholder for charts
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Mood trends chart")
                            .foregroundColor(.white.opacity(0.4))
                    }
                )
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Emotion distribution")
                            .foregroundColor(.white.opacity(0.4))
                    }
                )
        }
    }
}
