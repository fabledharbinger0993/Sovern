import SwiftUI

// MARK: - BeliefsNetworkView

/// Main view for visualizing belief network as hexagon nodes with connections
/// Core beliefs orbit at center, learned beliefs at outer ring
struct BeliefsNetworkView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var beliefSystem: BeliefSystem
    
    @State private var selectedBeliefId: UUID?
    @State private var showingDetailCard = false
    
    var body: some View {
        ZStack {
            // Neural pathway background
            NeuralPathwayBackground(style: .hexagonal)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Beliefs Network")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.textPrimary)
                    
                    // Coherence health indicator
                    let health = beliefSystem.coherenceScore
                    let healthColor: Color = health > 70 ? .green : (health > 50 ? .orange : .red)
                    let healthIcon: String = health > 70 ? "checkmark.circle.fill" : 
                                             (health > 50 ? "exclamationmark.circle.fill" : "xmark.circle.fill")
                    
                    HStack(spacing: 12) {
                        Label(
                            "\(beliefSystem.coreBeliefs.count) Core",
                            systemImage: "heart.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(themeManager.accentPrimary)
                        
                        Divider()
                            .frame(height: 12)
                        
                        Label(
                            "\(beliefSystem.learnedBeliefs.count) Learned",
                            systemImage: "sparkles"
                        )
                        .font(.caption)
                        .foregroundStyle(themeManager.textSecondary)
                        
                        Spacer()
                        
                        Label(
                            "Coherence: \(String(format: "%.0f", health))/100",
                            systemImage: healthIcon
                        )
                        .font(.caption)
                        .foregroundStyle(healthColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    
                    // Show tension warnings if any
                    let oscillatingBeliefs = beliefSystem.nodes.filter { $0.analyzeTension().unresolvedFlag }
                    if !oscillatingBeliefs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text("⚠️ \(oscillatingBeliefs.count) belief(s) oscillating")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(themeManager.cardBackground.opacity(0.5))
                
                // Network visualization
                BeliefsNetworkCanvas(
                    beliefSystem: beliefSystem,
                    selectedBeliefId: $selectedBeliefId,
                    showingDetailCard: $showingDetailCard
                )
                .frame(maxHeight: .infinity)
                
                // Belief list
                BeliefsListView(
                    beliefSystem: beliefSystem,
                    selectedBeliefId: $selectedBeliefId,
                    showingDetailCard: $showingDetailCard
                )
                .frame(height: 140)
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
            
            // Detail card overlay
            if showingDetailCard, let beliefId = selectedBeliefId,
               let belief = beliefSystem.belief(withId: beliefId) {
                BeliefDetailCard(
                    belief: belief,
                    isShowing: $showingDetailCard,
                    beliefSystem: beliefSystem
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - BeliefsNetworkCanvas

/// Canvas-based rendering of hexagon nodes and connections
struct BeliefsNetworkCanvas: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var beliefSystem: BeliefSystem
    @Binding var selectedBeliefId: UUID?
    @Binding var showingDetailCard: Bool
    
    let coreRadius: CGFloat = 100
    let learnedRadius: CGFloat = 220
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            
            ZStack {
                // Connection lines drawn first (so they're behind nodes)
                Canvas { context in
                    drawConnections(context, center: center)
                }
                
                // Core beliefs (inner circle)
                ForEach(beliefSystem.coreBeliefs, id: \.id) { belief in
                    let position = calculatePosition(
                        for: belief,
                        in: beliefSystem.coreBeliefs,
                        radius: coreRadius,
                        center: center
                    )
                    
                    BeliefNodeView(
                        belief: belief,
                        position: position,
                        isCorebelief: true
                    )
                    .onTapGesture {
                        selectedBeliefId = belief.id
                        showingDetailCard = true
                    }
                }
                
                // Learned beliefs (outer circle)
                ForEach(beliefSystem.learnedBeliefs, id: \.id) { belief in
                    let position = calculatePosition(
                        for: belief,
                        in: beliefSystem.learnedBeliefs,
                        radius: learnedRadius,
                        center: center
                    )
                    
                    BeliefNodeView(
                        belief: belief,
                        position: position,
                        isCorebelief: false
                    )
                    .onTapGesture {
                        selectedBeliefId = belief.id
                        showingDetailCard = true
                    }
                }
            }
        }
    }
    
    /// Draw connection lines between related beliefs
    private func drawConnections(_ context: GraphicsContext, center: CGPoint) {
        var drawnPairs: Set<String> = []
        
        for belief in beliefSystem.nodes {
            for connectionId in belief.connectionIds {
                let pairKey = [belief.id.uuidString, connectionId.uuidString].sorted().joined(separator: "-")
                
                guard !drawnPairs.contains(pairKey) else { continue }
                drawnPairs.insert(pairKey)
                
                guard let connectedBelief = beliefSystem.belief(withId: connectionId) else { continue }
                
                let isBeliefCore = beliefSystem.coreBeliefs.contains { $0.id == belief.id }
                let isConnectedCore = beliefSystem.coreBeliefs.contains { $0.id == connectionId }
                
                let beliefPos = calculatePosition(
                    for: belief,
                    in: isBeliefCore ? beliefSystem.coreBeliefs : beliefSystem.learnedBeliefs,
                    radius: isBeliefCore ? coreRadius : learnedRadius,
                    center: center
                )
                
                let connectedPos = calculatePosition(
                    for: connectedBelief,
                    in: isConnectedCore ? beliefSystem.coreBeliefs : beliefSystem.learnedBeliefs,
                    radius: isConnectedCore ? coreRadius : learnedRadius,
                    center: center
                )
                
                var path = Path()
                path.move(to: beliefPos)
                path.addLine(to: connectedPos)
                
                context.stroke(
                    path,
                    with: .color(
                        themeManager.borderColor.opacity(0.3)
                    ),
                    lineWidth: 1
                )
            }
        }
    }
    
    /// Calculate position of belief node in circular orbit
    private func calculatePosition(
        for belief: BeliefNode,
        in beliefList: [BeliefNode],
        radius: CGFloat,
        center: CGPoint
    ) -> CGPoint {
        guard let index = beliefList.firstIndex(where: { $0.id == belief.id }) else {
            return center
        }
        
        let angleSlice = 2 * CGFloat.pi / CGFloat(beliefList.count)
        let angle = angleSlice * CGFloat(index)
        
        let x = center.x + radius * cos(angle - .pi / 2)
        let y = center.y + radius * sin(angle - .pi / 2)
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - BeliefNodeView

/// Individual hexagon node with label
struct BeliefNodeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let belief: BeliefNode
    let position: CGPoint
    let isCorebelief: Bool
    
    var hexagonSize: CGFloat {
        // Range: weight 1-10 → size 12-40pt
        let normalized = CGFloat(belief.weight - 1) / 9.0
        return 12 + (normalized * 28)
    }
    
    var domainColor: Color {
        switch belief.domain {
        case .SELF:
            return Color(red: 1.0, green: 0.2, blue: 0.3)  // Red
        case .KNOWLEDGE:
            return Color(red: 0.3, green: 0.5, blue: 1.0)  // Blue
        case .ETHICS:
            return Color(red: 1.0, green: 0.8, blue: 0.2)  // Gold
        case .RELATIONAL:
            return Color(red: 0.8, green: 0.3, blue: 1.0)  // Purple
        case .META:
            return Color(red: 0.2, green: 0.8, blue: 0.6)  // Teal
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Hexagon
            ZStack {
                HexagonShape()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                domainColor.opacity(0.7),
                                domainColor.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .stroke(domainColor.opacity(0.8), lineWidth: 1)
                
                // Weight indicator (optional inner ring for emphasis)
                if isCorebelief {
                    HexagonShape()
                        .stroke(themeManager.accentPrimary.opacity(0.5), lineWidth: 0.5)
                        .padding(3)
                }
                
                // Weight badge
                Text("\(belief.weight)")
                    .font(.system(size: hexagonSize * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: hexagonSize, height: hexagonSize)
            
            // Label (below hexagon)
            Text(belief.stance)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(themeManager.textPrimary)
                .lineLimit(1)
                .frame(width: hexagonSize + 20)
                .padding(.top, 4)
        }
        .position(position)
    }
}

// MARK: - BeliefsListView

/// Scrollable list of all beliefs with quick select
struct BeliefsListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var beliefSystem: BeliefSystem
    @Binding var selectedBeliefId: UUID?
    @Binding var showingDetailCard: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("All Beliefs")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(beliefSystem.nodes, id: \.id) { belief in
                        BeliefBadgeView(
                            belief: belief,
                            isSelected: selectedBeliefId == belief.id,
                            isCorebelief: belief.isCore
                        )
                        .onTapGesture {
                            selectedBeliefId = belief.id
                            showingDetailCard = true
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(themeManager.cardBackground.opacity(0.3))
    }
}

// MARK: - BeliefBadgeView

/// Compact badge for belief list
struct BeliefBadgeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let belief: BeliefNode
    let isSelected: Bool
    let isCorebelief: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(belief.stance)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.textPrimary)
                
                Text("\(belief.weight)/10")
                    .font(.caption2)
                    .foregroundStyle(themeManager.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? themeManager.accentPrimary.opacity(0.3) : themeManager.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? themeManager.accentPrimary : themeManager.borderColor,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            
            if isCorebelief {
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(themeManager.accentPrimary)
            }
        }
    }
}

// MARK: - BeliefDetailCard

/// Overlay card showing belief details and revision history
struct BeliefDetailCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let belief: BeliefNode
    @Binding var isShowing: Bool
    let beliefSystem: BeliefSystem
    
    var body: some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.black.opacity(0.4))
                .onTapGesture { isShowing = false }
            
            // Card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(belief.stance)
                                .font(.headline)
                                .foregroundStyle(themeManager.textPrimary)
                            
                            HStack(spacing: 12) {
                                Label(belief.domain.description, systemImage: "tag.fill")
                                    .font(.caption)
                                    .foregroundStyle(themeManager.accentPrimary)
                                
                                if belief.isCore {
                                    Label("Core", systemImage: "heart.fill")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.accentPrimary)
                                } else {
                                    Label("Learned", systemImage: "sparkles")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.textSecondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { isShowing = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(themeManager.textSecondary)
                        }
                    }
                    
                    // Weight bar
                    VStack(spacing: 4) {
                        HStack {
                            Text("Belief Strength")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(themeManager.textSecondary)
                            
                            Spacer()
                            
                            Text("\(belief.weight)/10")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(themeManager.accentPrimary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.cardBackground)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.accentPrimary)
                                    .frame(width: geo.size.width * CGFloat(belief.weight) / 10)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .padding(16)
                .background(themeManager.cardBackground)
                
                Divider()
                    .foregroundStyle(themeManager.borderColor)
                
                // Reasoning
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reasoning")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.textSecondary)
                    
                    Text(belief.reasoning)
                        .font(.caption)
                        .foregroundStyle(themeManager.textPrimary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(themeManager.cardBackground)
                
                if !belief.revisionHistory.isEmpty {
                    Divider()
                        .foregroundStyle(themeManager.borderColor)
                    
                    // Revision history
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History (\(belief.revisionHistory.count) revisions)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(themeManager.textSecondary)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(belief.revisionHistory.reversed(), id: \.id) { revision in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(revision.type.rawValue.uppercased())
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(themeManager.accentPrimary)
                                            
                                            Spacer()
                                            
                                            Text(revision.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(themeManager.textSecondary)
                                        }
                                        
                                        Text(revision.reason)
                                            .font(.caption)
                                            .foregroundStyle(themeManager.textPrimary)
                                            .lineLimit(2)
                                    }
                                    .padding(8)
                                    .background(themeManager.cardBackground)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(themeManager.cardBackground)
                }
                
                // Connections
                if !belief.connectionIds.isEmpty {
                    Divider()
                        .foregroundStyle(themeManager.borderColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connected to (\(belief.connectionIds.count))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(themeManager.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(belief.connectionIds, id: \.self) { connectionId in
                                if let connected = beliefSystem.belief(withId: connectionId) {
                                    Text("→ \(connected.stance)")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.textPrimary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(themeManager.cardBackground)
                }
                
                Spacer()
            }
            .frame(maxWidth: 320)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.cardBackground,
                        themeManager.cardBackground.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(20)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    BeliefsNetworkView(beliefSystem: TestDataFactory.createTestBeliefSystem())
        .environmentObject(ThemeManager())
}
