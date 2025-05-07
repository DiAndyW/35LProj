//
//  ScrollTransitionExtension.swift
//  uclamoods
//
//  Created by Yang Gao on 5/5/25.
//

import SwiftUI

extension View {    
    // Static helper for transition offset calculation
    static func transitionOffset(for phase: ScrollTransitionPhase) -> Double {
        switch phase {
        case .topLeading:
            return 50
        case .identity:
            return 0
        case .bottomTrailing:
            return 50
        }
    }
}
