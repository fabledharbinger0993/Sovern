import SwiftUI

struct SovernTabNavigationView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var selectedTab: TabType = .chat
    
    enum TabType: String, CaseIterable {
        case chat = "chat"
        case logic = "logic"
        case memory = "memory"
        case beliefs = "beliefs"
        case settings = "settings"
        
        var title: String {
            switch self {
            case .chat: return "Chat"
            case .logic: return "Logic"
            case .memory: return "Memory"
            case .beliefs: return "Beliefs"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .chat: return "message.fill"
            case .logic: return "brain.head.profile"
            case .memory: return "book.fill"
            case .beliefs: return "hexagon.fill"
            case .settings: return "gear"
            }
        }
        
        var hexagonColor: HexagonButton.HexagonColor {
            switch self {
            case .logic: return .logic
            case .memory: return .memory
            default: return .neutral
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background with neural pathways
            WithNeuralPathway(style: .hexagonal) {
                tabContent
            }
            
            VStack {
                Spacer()
                
                // Bottom tab bar with hexagon buttons
                HStack(spacing: 16) {
                    ForEach(TabType.allCases, id: \.self) { tab in
                        VStack(spacing: 4) {
                            HexagonButton(
                                title: "",
                                icon: tab.icon,
                                size: .medium,
                                color: tab.hexagonColor
                            ) {
                                withAnimation {
                                    selectedTab = tab
                                }
                            }
                            
                            Text(tab.title)
                                .font(.caption)
                                .foregroundStyle(theme.textPrimary)
                        }
                        
                        if tab != TabType.allCases.last {
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .border(theme.borderColor, width: 1)
            }
        }
    }
    
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .chat:
            ChatTabView()
        case .logic:
            LogicTabView()
        case .memory:
            MemoryTabView()
        case .beliefs:
            BeliefsTabView()
        case .settings:
            SettingsTabView()
        }
    }
}

// MARK: - Tab Content Views (Placeholders)

struct ChatTabView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(theme.heartColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sovern")
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                    Text("Let's think together")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(12)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    MessageCard(
                        message: "Hi! I'm Sovern. What's on your mind?",
                        isUser: false
                    )
                }
                .padding(16)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                TextField("Ask Sovern...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(theme.textPrimary)
                
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(theme.accentPrimary)
            }
            .padding(16)
        }
        .padding(16)
    }
}

struct LogicTabView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(theme.logicButtonColor)
                        Text("Logic")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.textPrimary)
                    }
                    
                    Text("Congress debates & reasoning timeline")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(12)
            
            ScrollView {
                VStack(spacing: 12) {
                    InsightCard(
                        title: "Analysis: User value",
                        content: "Emotional safety is important",
                        isProfound: false
                    )
                    
                    InsightCard(
                        title: "Authentic care includes honest challenge",
                        content: "Sovern learned this through Congress debate",
                        isProfound: true
                    )
                }
                .padding(16)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

struct MemoryTabView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .foregroundStyle(theme.memoryButtonColor)
                        Text("Memory")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.textPrimary)
                    }
                    
                    Text("Learning insights & patterns")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(12)
            
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Human Insights")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.accentPrimary)
                        
                        Text("Values growth over comfort")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(12)
                    .background(theme.cardBackground)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Self Insights")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.memoryButtonColor)
                        
                        Text("Empathy includes being honest")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(12)
                    .background(theme.cardBackground)
                    .cornerRadius(8)
                }
                .padding(16)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

struct BeliefsTabView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beliefs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("Weighted hexagon network")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(12)
            
            ScrollView {
                VStack(spacing: 12) {
                    BeliefCard(stance: "Authenticity", weight: 9, domain: "ETHICS", isCore: true)
                    BeliefCard(stance: "Empathy", weight: 8, domain: "RELATIONAL", isCore: true)
                    BeliefCard(stance: "Growth", weight: 8, domain: "ETHICS", isCore: true)
                }
                .padding(16)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

struct SettingsTabView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.textPrimary)
                    
                    Text("Configuration & preferences")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(12)
            
            VStack(spacing: 12) {
                HStack {
                    Label("Dark Mode", systemImage: "moon.stars.fill")
                        .foregroundStyle(theme.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { theme.isDarkMode },
                        set: { _ in theme.toggleDarkMode() }
                    ))
                    .tint(theme.accentPrimary)
                }
                .padding(12)
                .background(theme.cardBackground)
                .cornerRadius(8)
            }
            .padding(16)
            
            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    SovernTabNavigationView()
        .environmentObject(ThemeManager())
}
