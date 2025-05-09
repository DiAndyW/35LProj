//
//  AdvancedTransitionModifier.swift
//  uclamoods
//
//  Created by Yang Gao on 5/8/25.
//
import SwiftUI

// This is now a wrapper around our unified MoodAnimations.TransitionModifier
struct AdvancedTransitionModifier: ViewModifier {
    let style: TransitionStyle
    let progress: CGFloat
    let originPoint: CGPoint
    let screenSize: CGSize
    
    func body(content: Content) -> some View {
        content.moodTransition(
            style: style,
            progress: progress,
            origin: originPoint,
            size: screenSize
        )
    }
}

// For backward compatibility - we keep this extension
extension View {
    func advancedTransition(
        style: TransitionStyle,
        progress: CGFloat,
        originPoint: CGPoint,
        screenSize: CGSize
    ) -> some View {
        modifier(AdvancedTransitionModifier(
            style: style,
            progress: progress,
            originPoint: originPoint,
            screenSize: screenSize
        ))
    }
}
