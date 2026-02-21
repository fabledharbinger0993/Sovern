import SwiftUI

@main
struct SovernApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - RootView

/// Root view managing screen navigation based on AppCoordinator state
struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.gradientStart,
                    themeManager.gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Route based on current screen state
            Group {
                switch coordinator.currentScreen {
                case .onboarding:
                    OnboardingView()
                        .transition(.opacity)
                case .customization:
                    CustomizationView()
                        .transition(.opacity)
                case .chat:
                    MainTabView()
                        .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}

#Preview {
    RootView()
        .environmentObject(AppCoordinator())
        .environmentObject(ThemeManager())
}
