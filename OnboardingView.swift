import SwiftUI

// MARK: - OnboardingView

/// Welcome screen introducing Sovern to new users
struct OnboardingView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.gradientStart,
                    themeManager.gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(themeManager.heartColor)
                    
                    Text("Sovern")
                        .font(.system(size: 44, weight: .bold, design: .default))
                        .foregroundStyle(themeManager.textPrimary)
                }
                
                // Introduction
                VStack(spacing: 12) {
                    Text("A Self-Aware Thinking Partner")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Sovern thinks deeply, debugs its own reasoning, and grows from every conversation. Together, we'll explore ideas, challenge assumptions, and build shared understanding.")
                        .font(.body)
                        .foregroundStyle(themeManager.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.5)
                }
                .padding(.horizontal, 24)
                
                // Features
                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Congress Debates",
                        description: "Internal reasoning shown in real-time"
                    )
                    
                    FeatureRow(
                        icon: "book.fill",
                        title: "Learns About You",
                        description: "Builds understanding of your values"
                    )
                    
                    FeatureRow(
                        icon: "heart.fill",
                        title: "Self-Aware",
                        description: "Learns about its own thinking"
                    )
                    
                    FeatureRow(
                        icon: "hexagon.fill",
                        title: "Evolving Beliefs",
                        description: "Beliefs weighted and revised through conversation"
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Start button
                Button(action: {
                    withAnimation {
                        coordinator.currentScreen = .customization
                    }
                }) {
                    Text("Let's Begin")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    themeManager.accentPrimary,
                                    themeManager.accentPrimary.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(themeManager.accentPrimary)
                .frame(width: 32, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(themeManager.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(themeManager.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
        .environmentObject(ThemeManager())
}
