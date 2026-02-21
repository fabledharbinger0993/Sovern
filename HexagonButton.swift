import SwiftUI

struct HexagonButton: View {
    @EnvironmentObject var theme: ThemeManager
    
    let title: String
    let icon: String?
    let size: HexagonSize
    let color: HexagonColor
    let action: () -> Void
    
    enum HexagonSize {
        case small  // ~24pt
        case medium // ~40pt
        case large  // ~60pt
        
        var dimension: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 40
            case .large: return 60
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
    }
    
    enum HexagonColor {
        case logic      // Orange (dark) or Gold (light)
        case memory     // Lavender (light) or Silver (dark)
        case neutral    // Primary accent
        
        func getColor(theme: ThemeManager) -> Color {
            switch self {
            case .logic:
                return theme.logicButtonColor
            case .memory:
                return theme.memoryButtonColor
            case .neutral:
                return theme.accentPrimary
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Hexagon background
                HexagonShape()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(color.getColor(theme: theme)).opacity(0.8),
                                Color(color.getColor(theme: theme)).opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .stroke(theme.borderColor, lineWidth: 1.5)
                
                VStack(spacing: 2) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.fontSize * 1.2))
                            .foregroundStyle(theme.textPrimary)
                    }
                    
                    if !title.isEmpty {
                        Text(title)
                            .font(.system(size: size.fontSize, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(4)
            }
            .frame(width: size.dimension, height: size.dimension)
        }
        .scaleEffect(0.95)
        .onHover { isHovered in
            // Add subtle scale animation on hover
        }
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        var path = Path()
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            HexagonButton(title: "Logic", icon: "brain.head.profile", size: .small, color: .logic) {}
            HexagonButton(title: "Memory", icon: "book.fill", size: .small, color: .memory) {}
            HexagonButton(title: "", icon: "heart.fill", size: .small, color: .neutral) {}
        }
        
        HStack(spacing: 20) {
            HexagonButton(title: "Logic", icon: "brain.head.profile", size: .medium, color: .logic) {}
            HexagonButton(title: "Memory", icon: "book.fill", size: .medium, color: .memory) {}
        }
        
        HStack(spacing: 20) {
            HexagonButton(title: "Logic", icon: "brain.head.profile", size: .large, color: .logic) {}
        }
    }
    .padding()
    .background(Color(.systemBackground))
    .environmentObject(ThemeManager())
}
