import SwiftUI

struct TransparentCard<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    
    let content: Content
    let borderColor: Color?
    let backgroundColor: Color?
    let cornerRadius: CGFloat
    
    init(
        @ViewBuilder content: () -> Content,
        borderColor: Color? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 12
    ) {
        self.content = content()
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(12)
        .background(
            (backgroundColor ?? theme.cardBackground)
                .blur(radius: 2)
        )
        .border(borderColor ?? theme.borderColor, width: 1)
        .cornerRadius(cornerRadius)
    }
}

// MARK: - Convenience Initializers

extension TransparentCard {
    
    /// Create a card with frame styling (gold/silver based on theme)
    init(
        frameStyle: FrameStyle = .adaptive,
        @ViewBuilder content: () -> Content
    ) {
        let env = EnvironmentValues()
        let theme = ThemeManager()
        
        self.content = content()
        
        switch frameStyle {
        case .adaptive:
            self.borderColor = theme.borderColor
        case .gold:
            self.borderColor = theme.darkGold.opacity(0.6)
        case .silver:
            self.borderColor = theme.silver.opacity(0.4)
        }
        
        self.backgroundColor = theme.cardBackground
        self.cornerRadius = 12
    }
    
    enum FrameStyle {
        case adaptive // Use theme's borderColor
        case gold     // Dark gold frame
        case silver   // Silver frame
    }
}

// MARK: - Specific Card Types

struct MessageCard: View {
    @EnvironmentObject var theme: ThemeManager
    
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }
            
            Text(message)
                .font(.body)
                .foregroundStyle(isUser ? .white : theme.textPrimary)
                .padding(12)
                .background(
                    isUser ? 
                        theme.accentPrimary : 
                        theme.cardBackground
                )
                .cornerRadius(12)
                .border(
                    !isUser ? theme.borderColor : .clear,
                    width: !isUser ? 1 : 0
                )
            
            if !isUser {
                Spacer()
            }
        }
    }
}

struct InsightCard: View {
    @EnvironmentObject var theme: ThemeManager
    
    let title: String
    let content: String
    let isProfound: Bool // For logic insights marked with ✨
    
    var body: some View {
        TransparentCard {
            VStack(alignment: .leading, spacing: 8) {
                if isProfound {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(theme.accentPrimary)
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)
                    }
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                }
                
                Text(content)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }
}

struct BeliefCard: View {
    @EnvironmentObject var theme: ThemeManager
    
    let stance: String
    let weight: Int // 1-10
    let domain: String
    let isCore: Bool
    
    var body: some View {
        TransparentCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stance)
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                        
                        // Weight bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.textSecondary.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.accentPrimary)
                                    .frame(width: geo.size.width * CGFloat(weight) / 10)
                            }
                        }
                        .frame(height: 4)
                        
                        Text("\(weight)%")
                            .font(.caption2)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                
                if isCore {
                    Image(systemName: "star.fill")
                        .foregroundStyle(theme.accentPrimary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TransparentCard {
            Text("Generic transparent card with frame")
                .font(.body)
                .foregroundStyle(.primary)
        }
        
        MessageCard(message: "This is a user message", isUser: true)
        
        MessageCard(message: "This is Sovern's response with reasoning", isUser: false)
        
        InsightCard(
            title: "Profound Insight",
            content: "Authentic care includes honest challenge",
            isProfound: true
        )
        
        BeliefCard(
            stance: "Authenticity",
            weight: 9,
            domain: "ETHICS",
            isCore: true
        )
    }
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.90),
                Color(red: 0.92, green: 0.88, blue: 0.98)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environmentObject(ThemeManager())
}
