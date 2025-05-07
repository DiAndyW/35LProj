import SwiftUI

// MARK: - Emotion Model
struct Emotion: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let description: String
    let pleasantness: Double    // Scale from 0.0 (negative) to 1.0 (positive)
    let intensity: Double  // Scale from 0.0 (mild) to 1.0 (strong)
    let control: Double    // Scale from 0.0 (out of control) to 1.0 (in control)
    let clarity: Double    // Scale from 0.0 (conflicted) to 1.0 (genuine)
}
