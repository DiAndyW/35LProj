// Toast.swift
import SwiftUI

enum ToastType {
    case error
    case warning
    case success
    case info

    var tintColor: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }

    var iconName: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastViewComponent: View { // Renamed to avoid conflict if you have another ToastView
    let type: ToastType
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.iconName)
                .foregroundColor(type.tintColor)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.white)
                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.black.opacity(0.75))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastType
    let duration: TimeInterval = 2.5

    func body(content: Content) -> some View {
        ZStack {
            content

            if isShowing {
                VStack {
                    Spacer()
                    HStack {
                        ToastViewComponent(type: type, message: message)
                            .frame(maxWidth: .infinity) // Allow toast to use available width
                        Spacer(minLength: 0) // Remove any extra spacing
                    }
                    .padding(.horizontal, 20) // Consistent horizontal padding
                    .padding(.bottom, 50) // More bottom padding for safe area
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
                .animation(.spring(), value: isShowing)
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, type: ToastType = .error) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, type: type))
    }
}
