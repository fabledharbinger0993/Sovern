import SwiftUI

// MARK: - SettingsView

/// Settings tab showing app configuration, sync status, and data management
struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingClearDataAlert = false
    @State private var showingExportData = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(themeManager.textPrimary)
                        
                        Text("Manage Sovern and sync settings")
                            .font(.caption)
                            .foregroundStyle(themeManager.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(themeManager.cardBackground)
                    .cornerRadius(12)
                    
                    // User & Appearance Section
                    SettingsSectionView(title: "Appearance & User") {
                        VStack(spacing: 12) {
                            HStack {
                                Label("Dark Mode", systemImage: "moon.stars.fill")
                                    .foregroundStyle(themeManager.textPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $themeManager.isDarkMode)
                            }
                            
                            if let context = coordinator.userContext {
                                Divider()
                                    .foregroundStyle(themeManager.borderColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("User")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.textSecondary)
                                    
                                    Text(context.name)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(themeManager.textPrimary)
                                    
                                    Text("Created \(context.createdDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(themeManager.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Sync Status Section
                    SettingsSectionView(title: "Sync Status") {
                        VStack(spacing: 12) {
                            // Online/Offline Status
                            HStack {
                                Image(systemName: "wifi")
                                    .foregroundStyle(
                                        coordinator.apiManager.isOnline ?
                                        themeManager.accentPrimary : .red
                                    )
                                
                                Text(coordinator.apiManager.isOnline ? "Online" : "Offline")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(themeManager.textPrimary)
                                
                                Spacer()
                                
                                Text(coordinator.apiManager.isOnline ? "✅" : "⚠️")
                                    .font(.body)
                            }
                            
                            Divider()
                                .foregroundStyle(themeManager.borderColor)
                            
                            // Sync Activity
                            HStack {
                                if coordinator.syncCoordinator.isSyncInProgress {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeManager.accentPrimary)
                                }
                                
                                Text(coordinator.syncCoordinator.isSyncInProgress ? "Syncing..." : "Sync Ready")
                                    .foregroundStyle(themeManager.textPrimary)
                                
                                Spacer()
                            }
                            
                            // Last Sync Time
                            if let lastSync = coordinator.apiManager.lastSyncTime {
                                Divider()
                                    .foregroundStyle(themeManager.borderColor)
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(themeManager.textSecondary)
                                    
                                    Text("Last Sync")
                                        .foregroundStyle(themeManager.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(themeManager.accentPrimary)
                                }
                            }
                            
                            // Queue Status
                            if !coordinator.apiManager.syncQueue.isEmpty {
                                Divider()
                                    .foregroundStyle(themeManager.borderColor)
                                
                                HStack {
                                    Image(systemName: "icloud.and.arrow.up.fill")
                                        .foregroundStyle(.orange)
                                    
                                    Text("\(coordinator.apiManager.syncQueue.count) items pending")
                                        .foregroundStyle(themeManager.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("Will sync when online")
                                        .font(.caption2)
                                        .foregroundStyle(themeManager.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Sync Statistics Section
                    SettingsSectionView(title: "Statistics") {
                        VStack(spacing: 12) {
                            StatRowView(
                                label: "Conversations",
                                value: String(coordinator.chatManager.messages.count / 2),
                                icon: "bubble.right.fill"
                            )
                            
                            Divider()
                                .foregroundStyle(themeManager.borderColor)
                            
                            StatRowView(
                                label: "Memory Entries",
                                value: String(coordinator.relationalMemory.entries.count),
                                icon: "book.fill"
                            )
                            
                            Divider()
                                .foregroundStyle(themeManager.borderColor)
                            
                            StatRowView(
                                label: "Beliefs",
                                value: String(coordinator.beliefSystem.nodes.count),
                                icon: "heart.fill"
                            )
                            
                            Divider()
                                .foregroundStyle(themeManager.borderColor)
                            
                            StatRowView(
                                label: "Coherence",
                                value: String(format: "%.0f", coordinator.beliefSystem.coherenceScore),
                                icon: "circle.circle.fill"
                            )
                        }
                    }
                    
                    // Recent Syncs Section
                    if !coordinator.syncCoordinator.syncHistory.isEmpty {
                        SettingsSectionView(title: "Recent Sync Activity") {
                            VStack(spacing: 8) {
                                ForEach(coordinator.syncCoordinator.syncHistory.reversed().prefix(5), id: \.id) { event in
                                    HStack(spacing: 8) {
                                        Text(event.status.emoji)
                                            .font(.caption)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.type.description)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(themeManager.textPrimary)
                                            
                                            Text(event.timestamp.formatted(time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(themeManager.textSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 6)
                                    
                                    if coordinator.syncCoordinator.syncHistory.reversed().prefix(5).last?.id != event.id {
                                        Divider()
                                            .foregroundStyle(themeManager.borderColor)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Data Management Section
                    SettingsSectionView(title: "Data Management") {
                        VStack(spacing: 12) {
                            Button(action: { showingExportData = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(themeManager.accentPrimary)
                                    
                                    Text("Export Data")
                                        .foregroundStyle(themeManager.accentPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(themeManager.textSecondary)
                                        .font(.caption)
                                }
                            }
                            
                            Divider()
                                .foregroundStyle(themeManager.borderColor)
                            
                            if !coordinator.apiManager.syncQueue.isEmpty {
                                Button(action: {
                                    coordinator.apiManager.processSyncQueue()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundStyle(themeManager.accentPrimary)
                                        
                                        Text("Retry Offline Queue")
                                            .foregroundStyle(themeManager.accentPrimary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(themeManager.textSecondary)
                                            .font(.caption)
                                    }
                                }
                                
                                Divider()
                                    .foregroundStyle(themeManager.borderColor)
                            }
                            
                            Button(action: { showingClearDataAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                    
                                    Text("Clear All Data")
                                        .foregroundStyle(.red)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(themeManager.textSecondary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // Info Section
                    SettingsSectionView(title: "About") {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(themeManager.textSecondary)
                                Spacer()
                                Text("v0.4.0")
                                    .foregroundStyle(themeManager.accentPrimary)
                            }
                            
                            Divider()
                                .foregroundStyle(themeManager.borderColor)
                            
                            HStack {
                                Text("Built with")
                                    .foregroundStyle(themeManager.textSecondary)
                                Spacer()
                                Text("SwiftUI + Python")
                                    .foregroundStyle(themeManager.accentPrimary)
                            }
                        }
                    }
                    
                    // Reset button
                    Button(action: { coordinator.resetUserContext() }) {
                        Text("Start Over")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.gradientStart,
                        themeManager.gradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    coordinator.clearAllData()
                }
            } message: {
                Text("This will permanently delete all chat, memory, and logic data. This cannot be undone.")
            }
        }
    }
}

// MARK: - Settings Section

struct SettingsSectionView<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.textSecondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Stat Row

struct StatRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(themeManager.accentPrimary)
                .frame(width: 20)
            
            Text(label)
                .foregroundStyle(themeManager.textSecondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(themeManager.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppCoordinator())
        .environmentObject(ThemeManager())
}
