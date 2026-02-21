import SwiftUI

// MARK: - MainTabView

/// Main navigation view connecting all 5 tabs with proper state management
struct MainTabView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab: TabType = .chat
    
    enum TabType: String, CaseIterable, Hashable {
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
            // Main content area
            ZStack {
                // Background gradient with neural pathways
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.gradientStart,
                        themeManager.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Neural pathway overlay
                NeuralPathwayBackground(style: .hexagonal)
                
                // Tab content
                Group {
                    switch selectedTab {
                    case .chat:
                        ChatView()
                    case .logic:
                        LogicDetailView()
                    case .memory:
                        MemoryViewTab()
                    case .beliefs:
                        BeliefsNetworkView()
                    case .settings:
                        SettingsView()
                    }
                }
                .transition(.opacity)
            }
            
            // Bottom tab bar
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    ForEach(TabType.allCases, id: \.self) { tab in
                        VStack(spacing: 6) {
                            ZStack {
                                // Hexagon button styling
                                HexagonButton(
                                    title: "",
                                    icon: tab.icon,
                                    size: .medium,
                                    color: selectedTab == tab ? tab.hexagonColor : .neutral
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTab = tab
                                    }
                                }
                                
                                // Selection indicator
                                if selectedTab == tab {
                                    HexagonShape()
                                        .stroke(themeManager.accentPrimary, lineWidth: 2)
                                        .frame(width: 42, height: 42)
                                }
                            }
                            
                            Text(tab.title)
                                .font(.caption2)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundStyle(
                                    selectedTab == tab ?
                                    themeManager.accentPrimary :
                                    themeManager.textSecondary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(
                    themeManager.cardBackground
                        .ignoresSafeArea(edges: .bottom)
                )
                .border(themeManager.borderColor, width: 1)
            }
        }
        .onAppear {
            // Route to chat tab on app start
            selectedTab = .chat
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AppCoordinator())
        .environmentObject(ThemeManager())
}
