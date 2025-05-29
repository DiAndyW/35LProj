import SwiftUI

struct MoodAppContainer: View {
    @StateObject private var router = MoodAppRouter()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Consistent background
                Color.black.edgesIgnoringSafeArea(.all)
                
                Group {
                    switch router.currentSection {
                    case .auth:
                        AuthFlowView()
                        
                    case .main:
                        MainAppView()
                        
                    case .moodFlow:
                        MoodFlowContainer()
                    }
                }
            }
            .environmentObject(router)
            .onAppear {
                router.setScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                router.setScreenSize(newSize)
            }
        }
    }
}

// MARK: - Auth Flow (Same as before)
struct AuthFlowView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        Group {
            switch router.currentAuthScreen {
            case .signIn:
                SignInView()
                    .transition(.slide)
                
            case .signUp:
                SignUpView()
                    .transition(.slide)
                
            case .completeProfile:
                CompleteProfileView()
                    .transition(.slide)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.currentAuthScreen)
    }
}

// MARK: - 3-Tab Main App with Swipe Navigation
struct MainAppView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        TabView(selection: $router.selectedMainTab) {
            // Home/Feed Tab
            HomeFeedView()
                .tag(MoodAppRouter.MainTab.home)
            
            // Profile Tab (includes settings and analytics)
            ProfileView()
                .tag(MoodAppRouter.MainTab.profile)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default dots
        .edgesIgnoringSafeArea(.bottom)
        .overlay(
            // Custom 3-tab bar overlay
            VStack {
                Spacer()
                ThreeTabBar()
            }
        )
    }
}

// MARK: - Custom 3-Tab Bar with Prominent Check-In Button
struct ThreeTabBar: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        HStack {
            // Home Tab
            TabBarButton(
                tab: .home,
                isSelected: router.selectedMainTab == .home
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    router.selectTab(.home)
                }
            }
            
            Spacer()
            
            // Check-In Button (Prominent Middle Button)
            CheckInButton {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                
                router.navigateToMoodFlow()
            }
            
            Spacer()
            
            // Profile Tab
            TabBarButton(
                tab: .profile,
                isSelected: router.selectedMainTab == .profile
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    router.selectTab(.profile)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .padding(.bottom, 20) // Account for safe area
        .background(
            // Glassmorphism effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                )
        )
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 25, bottomLeading: 0,
            bottomTrailing: 0, topTrailing: 25
        )))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Tab Bar Button Component
struct TabBarButton: View {
    let tab: MoodAppRouter.MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.iconNameFilled : tab.iconName)
                    .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Prominent Check-In Button
struct CheckInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .pink.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Pulsing animation ring
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .opacity(isPressed ? 0 : 1)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Continuous subtle pulse animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPressed = true
            }
        }
    }
}

// MARK: - Mood Flow Container (Same as before)
struct MoodFlowContainer: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch router.currentMoodFlowScreen {
                case .energySelection:
                    EnergySelectionView()
                        .moodTransition(
                            style: router.moodFlowTransitionStyle,
                            progress: router.moodFlowTransitionProgress,
                            origin: router.moodFlowTransitionOrigin,
                            size: geometry.size
                        )
                        
                case .emotionSelection(let energyLevel):
                    EmotionSelectionView(energyLevel: energyLevel)
                        .moodTransition(
                            style: router.moodFlowTransitionStyle,
                            progress: router.moodFlowTransitionProgress,
                            origin: router.moodFlowTransitionOrigin,
                            size: geometry.size
                        )
                        
                case .completeCheckIn(let emotion):
                    CompleteCheckInView(emotion: emotion)
                        .moodTransition(
                            style: router.moodFlowTransitionStyle,
                            progress: router.moodFlowTransitionProgress,
                            origin: router.moodFlowTransitionOrigin,
                            size: geometry.size
                        )
                }
            }
        }
    }
}

#Preview {
    MoodAppContainer()
}
