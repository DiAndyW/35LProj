import UIKit
import SwiftUI

// A utility class to manage different types of haptic feedback
class HapticFeedbackManager {
    // Singleton instance
    static let shared = HapticFeedbackManager()
    
    // Different feedback generators for various interactions
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // Private initializer for singleton pattern
    private init() {
        // Pre-prepare all generators to reduce latency
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Public Methods
    
    /// Plays selection change haptic feedback
    /// Use when: User selects from a list of items or navigates through options
    func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare() // Prepare for next use
    }
    
    /// Plays a light impact haptic
    /// Use when: Subtle interactions like minor UI state changes
    func lightImpact() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare()
    }
    
    /// Plays a medium impact haptic
    /// Use when: Standard interactions like button presses
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
    }
    
    /// Plays a heavy impact haptic
    /// Use when: Significant interactions or confirmations
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
        heavyImpactGenerator.prepare()
    }
    
    /// Plays a success notification haptic
    /// Use when: Operation completed successfully
    func successNotification() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// Plays a warning notification haptic
    /// Use when: Warning the user about something
    func warningNotification() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// Plays an error notification haptic
    /// Use when: Operation failed or error occurred
    func errorNotification() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}

// SwiftUI View extension for easier haptic feedback access
extension View {
    /// Adds haptic feedback when a value changes
    /// - Parameters:
    ///   - value: The value to watch for changes
    ///   - feedbackType: The type of feedback to generate
    /// - Returns: A modified view that triggers haptic feedback on value changes
    func hapticFeedback<Value: Equatable>(
        on value: Value,
        type: HapticFeedbackType
    ) -> some View {
        return self.onChange(of: value) { oldValue, newValue in
            if oldValue != newValue {
                switch type {
                case .selection:
                    HapticFeedbackManager.shared.selectionChanged()
                case .light:
                    HapticFeedbackManager.shared.lightImpact()
                case .medium:
                    HapticFeedbackManager.shared.mediumImpact()
                case .heavy:
                    HapticFeedbackManager.shared.heavyImpact()
                case .success:
                    HapticFeedbackManager.shared.successNotification()
                case .warning:
                    HapticFeedbackManager.shared.warningNotification()
                case .error:
                    HapticFeedbackManager.shared.errorNotification()
                }
            }
        }
    }
}

// Enum to simplify the choice of haptic feedback types
enum HapticFeedbackType {
    case selection
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}
