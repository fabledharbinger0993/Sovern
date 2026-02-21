import SwiftUI

/// LogicDetailView - Display complete Congress debate with reasoning timeline
/// Shows reasoning steps, perspectives, candidate responses, and insights
struct LogicDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    let logicEntry: LogicEntry
    
    @State private var expandedPerspectiveId: UUID?
    @State private var expandedStepId: UUID?
    @State private var expandedCandidateId: UUID?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Congress Debate")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text(logicEntry.userQuery)
                            .font(.system(.body, design: .default))
                            .foregroundColor(themeManager.textSecondary)
                            .lineLimit(3)
                        
                        HStack(spacing: 12) {
                            // Complexity badge
                            Text(logicEntry.complexityCategory.rawValue.capitalized)
                                .font(.system(.caption, design: .default))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(complexityColor())
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            
                            // Congress engaged badge
                            if logicEntry.congressEngaged {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 12))
                                    Text("Congress")
                                        .font(.system(.caption, design: .default))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.accentPrimary.opacity(0.3))
                                .foregroundColor(themeManager.accentPrimary)
                                .cornerRadius(6)
                            }
                            
                            Spacer()
                            
                            // Weight meter
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Weight")
                                    .font(.system(.caption2, design: .default))
                                    .foregroundColor(themeManager.textSecondary)
                                
                                HStack(spacing: 4) {
                                    Text("\(String(format: "%.1f", logicEntry.weight))")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(themeManager.textPrimary)
                                    
                                    ProgressView(value: logicEntry.weight / 9.0)
                                        .frame(width: 40)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(themeManager.cardBackground)
                    .cornerRadius(8)
                    
                    // Reasoning Timeline
                    if !logicEntry.reasoningSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reasoning Timeline")
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(logicEntry.reasoningSteps.enumerated()), id: \.element.id) { index, step in
                                    ReasoningStepView(
                                        step: step,
                                        isLast: index == logicEntry.reasoningSteps.count - 1,
                                        isExpanded: expandedStepId == step.id,
                                        onTap: {
                                            withAnimation {
                                                expandedStepId = expandedStepId == step.id ? nil : step.id
                                            }
                                        }
                                    )
                                    .environmentObject(themeManager)
                                }
                            }
                        }
                    }
                    
                    // Congress Perspectives
                    if logicEntry.congressEngaged && !logicEntry.perspectives.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Congress Perspectives")
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            ForEach(logicEntry.perspectives.sorted { $0.callNumber < $1.callNumber }, id: \.id) { perspective in
                                PerspectiveCardView(
                                    perspective: perspective,
                                    isExpanded: expandedPerspectiveId == perspective.id,
                                    onTap: {
                                        withAnimation {
                                            expandedPerspectiveId = expandedPerspectiveId == perspective.id ? nil : perspective.id
                                        }
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                        }
                    }
                    
                    // Candidate Responses
                    if !logicEntry.candidateResponses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(format: "Response Drafts (%d)", logicEntry.candidateResponses.count))
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            ForEach(logicEntry.candidateResponses, id: \.id) { candidate in
                                CandidateResponseView(
                                    candidate: candidate,
                                    isExpanded: expandedCandidateId == candidate.id,
                                    onTap: {
                                        withAnimation {
                                            expandedCandidateId = expandedCandidateId == candidate.id ? nil : candidate.id
                                        }
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                        }
                    }
                    
                    // Profound Insights
                    if !logicEntry.profoundInsights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("✨ Profound Insights")
                                    .font(.system(.headline, design: .default))
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Spacer()
                                
                                Text("\(logicEntry.profoundInsights.count)")
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(themeManager.accentPrimary.opacity(0.2))
                                    .foregroundColor(themeManager.accentPrimary)
                                    .cornerRadius(4)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(logicEntry.profoundInsights, id: \.self) { insight in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("✨")
                                            .font(.system(size: 16))
                                        
                                        Text(insight)
                                            .font(.system(.body, design: .default))
                                            .foregroundColor(themeManager.textPrimary)
                                    }
                                    .padding(8)
                                    .background(themeManager.cardBackground)
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    
                    // Final Response
                    if !logicEntry.finalResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Final Response")
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            Text(logicEntry.finalResponse)
                                .font(.system(.body, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                                .textSelection(.enabled)
                                .padding(12)
                                .background(themeManager.cardBackground)
                                .cornerRadius(8)
                        }
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(themeManager.textSecondary)
                        
                        MetaRow(label: "Paradigm", value: logicEntry.paradigmRouting)
                        MetaRow(label: "Strategy", value: logicEntry.engagementStrategy.rawValue)
                        MetaRow(label: "Timestamp", value: logicEntry.timestamp.formatted())
                        MetaRow(label: "ID", value: String(logicEntry.id.uuidString.prefix(8)).uppercased())
                    }
                    .padding(12)
                    .background(themeManager.cardBackground)
                    .cornerRadius(8)
                }
                .padding(16)
            }
            .background(
                WithNeuralPathway(
                    pathwayStyle: .linear,
                    gradient: Gradient(colors: [
                        Color(themeManager.gradientStart),
                        Color(themeManager.gradientEnd)
                    ])
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func complexityColor() -> Color {
        switch logicEntry.complexityCategory {
        case .simple: return themeManager.accentSecondary
        case .moderate: return themeManager.accentPrimary
        case .complex: return Color.red
        }
    }
}

// MARK: - Reasoning Step View

struct ReasoningStepView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let step: ReasoningStep
    let isLast: Bool
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .center, spacing: 0) {
                    // Timeline circle with icon
                    ZStack {
                        Circle()
                            .fill(stepColor())
                            .frame(width: 32, height: 32)
                        
                        Text(step.type.emoji)
                            .font(.system(size: 16))
                    }
                    
                    // Timeline line (if not last)
                    if !isLast {
                        VStack {
                            Divider()
                                .frame(height: 40)
                                .foregroundColor(themeManager.borderColor.opacity(0.5))
                        }
                        .frame(width: 1)
                    }
                }
                .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.type.rawValue.capitalized)
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            Text(step.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(themeManager.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.accentSecondary)
                    }
                    
                    if isExpanded {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text(step.content)
                            .font(.system(.body, design: .default))
                            .foregroundColor(themeManager.textPrimary)
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
    
    private func stepColor() -> Color {
        switch step.type {
        case .analysis: return Color.blue
        case .concern: return Color.orange
        case .debate: return Color.purple
        case .insight: return Color.yellow
        case .revision: return Color.green
        }
    }
}

// MARK: - Perspective Card View

struct PerspectiveCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let perspective: CongressPerspective
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Role icon/circle
                ZStack {
                    Circle()
                        .fill(themeManager.accentPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(perspective.role.emoji)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(perspective.role.rawValue.capitalized)
                                .font(.system(.headline, design: .default))
                                .foregroundColor(themeManager.textPrimary)
                            
                            if perspective.callNumber > 0 {
                                Text("Call \(perspective.callNumber)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(themeManager.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Strength meter
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f/10", perspective.strengthOfArgument))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(themeManager.textSecondary)
                            
                            ProgressView(value: perspective.strengthOfArgument / 10.0)
                                .frame(width: 60)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.accentSecondary)
                    }
                    
                    Text(perspective.position)
                        .font(.system(.body, design: .default))
                        .foregroundColor(themeManager.textPrimary)
                        .lineLimit(isExpanded ? .max : 1)
                    
                    if isExpanded && !perspective.reasoning.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text(perspective.reasoning)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(themeManager.textSecondary)
                        
                        // Show linked beliefs (especially for Advocate/Skeptic)
                        if !perspective.linkedBeliefIds.isEmpty && (perspective.role == .advocate || perspective.role == .skeptic) {
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Grounded in:")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(themeManager.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(perspective.linkedBeliefIds.prefix(3), id: \.self) { beliefId in
                                        HStack(spacing: 4) {
                                            Image(systemName: "bookmark.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(themeManager.accentPrimary)
                                            
                                            Text(beliefId.uuidString.prefix(8).uppercased())
                                                .font(.system(.caption2, design: .monospaced))
                                                .foregroundColor(themeManager.textPrimary)
                                        }
                                    }
                                    
                                    if perspective.linkedBeliefIds.count > 3 {
                                        Text("+\(perspective.linkedBeliefIds.count - 3) more beliefs")
                                            .font(.system(.caption2, design: .default))
                                            .foregroundColor(themeManager.accentSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(themeManager.cardBackground)
            .cornerRadius(8)
            .onTapGesture(perform: onTap)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Candidate Response View

struct CandidateResponseView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let candidate: CandidateResponse
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Status badge
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: statusIcon())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(statusColor())
                    
                    Text("Draft \(candidate.draftNumber)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(candidate.status.rawValue.capitalized)
                                    .font(.system(.headline, design: .default))
                                    .foregroundColor(themeManager.textPrimary)
                                
                                if candidate.status == .selected {
                                    Text("✓")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Text(candidate.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(themeManager.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.accentSecondary)
                    }
                    
                    if isExpanded {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text(candidate.content)
                            .font(.system(.body, design: .default))
                            .foregroundColor(themeManager.textPrimary)
                        
                        if !candidate.rejectionReason.isEmpty {
                            Divider()
                                .padding(.vertical, 8)
                            
                            HStack(alignment: .top, spacing: 6) {
                                Text("Why:")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(themeManager.textSecondary)
                                
                                Text(candidate.rejectionReason ?? "")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(themeManager.textPrimary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(themeManager.cardBackground)
            .cornerRadius(8)
            .onTapGesture(perform: onTap)
            .contentShape(Rectangle())
        }
    }
    
    private func statusIcon() -> String {
        switch candidate.status {
        case .selected: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .considering: return "minus.circle.fill"
        }
    }
    
    private func statusColor() -> Color {
        switch candidate.status {
        case .selected: return .green
        case .rejected: return .red
        case .considering: return .orange
        }
    }
}

// MARK: - Supporting Views

struct MetaRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .default))
                .foregroundColor(themeManager.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(themeManager.textPrimary)
        }
    }
}

#Preview {
    let themeManager = ThemeManager()
    let logicEntry = TestDataFactory.createComplexLogicEntry()
    
    return LogicDetailView(logicEntry: logicEntry)
        .environmentObject(themeManager)
        .preferredColorScheme(nil)
}
