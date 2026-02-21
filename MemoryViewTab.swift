import SwiftUI

/// MemoryViewTab - Display learning insights and patterns
/// Shows what Sovern learned about the human vs. what it learned about itself
struct MemoryViewTab: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var memory: RelationalMemory
    
    @State private var selectedTab: MemoryTab = .insights
    @State private var expandedInsightId: UUID?
    @State private var expandedPatternId: UUID?
    @State private var filterCategory: InsightCategory? = nil
    
    enum MemoryTab {
        case insights
        case patterns
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Memory")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(themeManager.textPrimary)
                
                Text("What I've learned about you and myself")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding(16)
            .background(themeManager.cardBackground)
            .border(themeManager.borderColor, width: 1)
            
            // Tab selector
            HStack(spacing: 0) {
                TabButton(
                    label: "Insights",
                    isSelected: selectedTab == .insights,
                    action: { withAnimation { selectedTab = .insights } }
                )
                .environmentObject(themeManager)
                
                TabButton(
                    label: "Patterns",
                    isSelected: selectedTab == .patterns,
                    action: { withAnimation { selectedTab = .patterns } }
                )
                .environmentObject(themeManager)
                
                Spacer()
            }
            .padding(8)
            .background(themeManager.cardBackground)
            .border(themeManager.borderColor, width: 1)
            
            // Content
            ZStack {
                if selectedTab == .insights {
                    InsightsViewContent(
                        expandedInsightId: $expandedInsightId,
                        filterCategory: $filterCategory
                    )
                    .environmentObject(themeManager)
                    .environmentObject(memory)
                } else {
                    PatternsViewContent(
                        expandedPatternId: $expandedPatternId
                    )
                    .environmentObject(themeManager)
                    .environmentObject(memory)
                }
            }
        }
        .background(
            WithNeuralPathway(
                pathwayStyle: .hexagonal,
                gradient: Gradient(colors: [
                    Color(themeManager.gradientStart),
                    Color(themeManager.gradientEnd)
                ])
            )
        )
    }
}

// MARK: - Insights View Content

struct InsightsViewContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var memory: RelationalMemory
    
    @Binding var expandedInsightId: UUID?
    @Binding var filterCategory: InsightCategory?
    
    var humanInsights: [Insight] {
        let all = memory.allHumanInsights
        return filterCategory.map { cat in all.filter { $0.category == cat } } ?? all
    }
    
    var selfInsights: [Insight] {
        let all = memory.allSelfInsights
        return filterCategory.map { cat in all.filter { $0.category == cat } } ?? all
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter buttons
                if !InsightCategory.allCases.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter by Category")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(themeManager.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // Clear filter button
                                Button(action: { filterCategory = nil }) {
                                    Text("All")
                                        .font(.system(.caption, design: .default))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(filterCategory == nil ? themeManager.accentPrimary : themeManager.cardBackground)
                                        .foregroundColor(filterCategory == nil ? .white : themeManager.textPrimary)
                                        .cornerRadius(6)
                                }
                                
                                // Category buttons
                                ForEach(InsightCategory.allCases, id: \.self) { category in
                                    Button(action: { filterCategory = category }) {
                                        HStack(spacing: 4) {
                                            Text(category.emoji)
                                                .font(.system(size: 12))
                                            Text(category.shortLabel)
                                                .font(.system(.caption2, design: .default))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(filterCategory == category ? themeManager.accentPrimary : themeManager.cardBackground)
                                        .foregroundColor(filterCategory == category ? .white : themeManager.textPrimary)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(themeManager.cardBackground.opacity(0.5))
                    .cornerRadius(8)
                }
                
                // Human Insights Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("What I Learned About You")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(themeManager.textPrimary)
                        
                        Spacer()
                        
                        Text("\(humanInsights.count)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.accentSecondary.opacity(0.2))
                            .foregroundColor(themeManager.accentSecondary)
                            .cornerRadius(4)
                    }
                    
                    if humanInsights.isEmpty {
                        EmptyStateView(message: "No insights yet. Have a conversation to start learning!")
                            .environmentObject(themeManager)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(humanInsights, id: \.id) { insight in
                                InsightCardView(
                                    insight: insight,
                                    isExpanded: expandedInsightId == insight.id,
                                    onTap: {
                                        withAnimation {
                                            expandedInsightId = expandedInsightId == insight.id ? nil : insight.id
                                        }
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                        }
                    }
                }
                
                // Self Insights Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("What I Learned About Myself")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(themeManager.textPrimary)
                        
                        Spacer()
                        
                        Text("\(selfInsights.count)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.accentPrimary.opacity(0.2))
                            .foregroundColor(themeManager.accentPrimary)
                            .cornerRadius(4)
                    }
                    
                    if selfInsights.isEmpty {
                        EmptyStateView(message: "Self-insights will appear as Sovern reflects on its own reasoning patterns")
                            .environmentObject(themeManager)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(selfInsights, id: \.id) { insight in
                                InsightCardView(
                                    insight: insight,
                                    isExpanded: expandedInsightId == insight.id,
                                    onTap: {
                                        withAnimation {
                                            expandedInsightId = expandedInsightId == insight.id ? nil : insight.id
                                        }
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Patterns View Content

struct PatternsViewContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var memory: RelationalMemory
    
    @Binding var expandedPatternId: UUID?
    
    var patterns: [LearnedPattern] {
        memory.allLearnedPatterns.sorted { $0.frequency > $1.frequency }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if patterns.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.accentSecondary)
                        
                        VStack(spacing: 8) {
                            Text("No Patterns Yet")
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            Text("Patterns emerge from multiple conversations. Keep talking with Sovern to discover recurring themes!")
                                .font(.system(.caption, design: .default))
                                .foregroundColor(themeManager.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(32)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recurring Patterns")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("\(patterns.count) patterns identified across conversations")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(12)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(patterns.enumerated()), id: \.element.id) { index, pattern in
                            PatternCardView(
                                pattern: pattern,
                                rank: index + 1,
                                isExpanded: expandedPatternId == pattern.id,
                                onTap: {
                                    withAnimation {
                                        expandedPatternId = expandedPatternId == pattern.id ? nil : pattern.id
                                    }
                                }
                            )
                            .environmentObject(themeManager)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
}

// MARK: - Insight Card View

struct InsightCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let insight: Insight
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                // Category emoji
                Text(insight.category.emoji)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.category.rawValue)
                                .font(.system(.caption, design: .default))
                                .foregroundColor(themeManager.textSecondary)
                            
                            Text(insight.content)
                                .font(.system(.body, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                                .lineLimit(isExpanded ? .max : 2)
                        }
                        
                        Spacer(minLength: 8)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.accentSecondary)
                    }
                    
                    if isExpanded {
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Extended details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(insight.source)
                                .font(.system(.caption2, design: .default))
                                .foregroundColor(themeManager.textSecondary)
                                .padding(6)
                                .background(themeManager.cardBackground)
                                .cornerRadius(4)
                            
                            if let beliefId = insight.relatedBeliefId {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 10))
                                    Text("Linked to belief")
                                        .font(.system(.caption2, design: .default))
                                    Text(beliefId.uuidString.prefix(8).uppercased())
                                        .font(.system(.caption2, design: .monospaced))
                                }
                                .foregroundColor(themeManager.accentPrimary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.xmark")
                                    .font(.system(size: 10))
                                Text(insight.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(.caption2, design: .monospaced))
                            }
                            .foregroundColor(themeManager.textSecondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(themeManager.cardBackground)
            .cornerRadius(8)
            .onTapGesture(perform: onTap)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Pattern Card View

struct PatternCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let pattern: LearnedPattern
    let rank: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Rank badge
                VStack(alignment: .center, spacing: 4) {
                    Text("#\(rank)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(themeManager.accentPrimary)
                        .cornerRadius(14)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pattern.pattern)
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            Text(String(format: "%.0f% frequency", pattern.frequency * 100))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(themeManager.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Frequency bar
                        ProgressView(value: pattern.frequency)
                            .frame(width: 60)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.accentSecondary)
                    }
                    
                    if isExpanded {
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Evidence
                        if !pattern.evidence.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Evidence")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(themeManager.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(pattern.evidence.prefix(3), id: \.self) { item in
                                        HStack(spacing: 4) {
                                            Text("•")
                                                .foregroundColor(themeManager.accentSecondary)
                                            Text(item)
                                                .font(.system(.caption, design: .default))
                                                .foregroundColor(themeManager.textPrimary)
                                        }
                                    }
                                    if pattern.evidence.count > 3 {
                                        Text("+\(pattern.evidence.count - 3) more")
                                            .font(.system(.caption2, design: .default))
                                            .foregroundColor(themeManager.accentSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(themeManager.cardBackground)
            .cornerRadius(8)
            .onTapGesture(perform: onTap)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(label)
                    .font(.system(.body, design: .default))
                    .foregroundColor(isSelected ? themeManager.accentPrimary : themeManager.textSecondary)
                
                if isSelected {
                    Capsule()
                        .fill(themeManager.accentPrimary)
                        .frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.circle")
                .font(.system(size: 32))
                .foregroundColor(themeManager.accentSecondary)
            
            Text(message)
                .font(.system(.caption, design: .default))
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(themeManager.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Extensions

extension InsightCategory {
    var shortLabel: String {
        label.split(separator: " ").first.map(String.init) ?? label
    }
}

#Preview {
    let themeManager = ThemeManager()
    let memory = TestDataFactory.createComplexMemoryEntry()
    let relationalMemory = RelationalMemory()
    relationalMemory.add(memory)
    
    return MemoryViewTab()
        .environmentObject(themeManager)
        .environmentObject(relationalMemory)
        .preferredColorScheme(nil)
}
