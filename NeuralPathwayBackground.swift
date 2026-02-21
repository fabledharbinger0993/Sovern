import SwiftUI

struct NeuralPathwayBackground: View {
    @EnvironmentObject var theme: ThemeManager
    
    let opacity: Double
    let style: PathwayStyle
    
    enum PathwayStyle {
        case linear      // Diagonal lines
        case hexagonal   // Hexagon network pattern
        case organic     // Curved connecting paths
    }
    
    var body: some View {
        Canvas { context in
            let rect = context.environment.bounds
            let pathColor = theme.isDarkMode ? 
                theme.silver.opacity(0.15) : 
                theme.darkGold.opacity(0.2)
            
            switch style {
            case .linear:
                drawLinearPathways(in: rect, context: context, color: pathColor)
            case .hexagonal:
                drawHexagonalPathways(in: rect, context: context, color: pathColor)
            case .organic:
                drawOrganicPathways(in: rect, context: context, color: pathColor)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Linear Pathways
    
    private func drawLinearPathways(
        in rect: CGRect,
        context: inout GraphicsContext,
        color: Color
    ) {
        let spacing: CGFloat = 80
        let angle: CGFloat = 0.3 // Radians, for diagonal
        
        var x: CGFloat = -rect.width
        while x < rect.width * 2 {
            var path = Path()
            path.move(to: CGPoint(
                x: x,
                y: -rect.height
            ))
            path.addLine(to: CGPoint(
                x: x + rect.height / tan(angle),
                y: rect.height * 2
            ))
            
            context.stroke(
                path,
                with: .color(color),
                lineWidth: 1
            )
            
            x += spacing
        }
    }
    
    // MARK: - Hexagonal Network Pathways
    
    private func drawHexagonalPathways(
        in rect: CGRect,
        context: inout GraphicsContext,
        color: Color
    ) {
        let spacing: CGFloat = 60
        let hexRadius: CGFloat = 30
        
        var x: CGFloat = hexRadius
        while x < rect.width {
            var y: CGFloat = hexRadius
            while y < rect.height {
                drawHexagonNode(
                    at: CGPoint(x: x, y: y),
                    radius: hexRadius,
                    context: &context,
                    color: color
                )
                
                // Connect to right neighbor
                if x + spacing * 2 < rect.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + spacing * 2, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 0.8)
                }
                
                // Connect to bottom-right neighbor
                if x + spacing < rect.width && y + spacing < rect.height {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + spacing, y: y + spacing))
                    context.stroke(path, with: .color(color), lineWidth: 0.8)
                }
                
                y += spacing
            }
            x += spacing * 2
        }
    }
    
    // MARK: - Organic Curved Pathways
    
    private func drawOrganicPathways(
        in rect: CGRect,
        context: inout GraphicsContext,
        color: Color
    ) {
        let points = generateOrganicPoints(in: rect, count: 8)
        
        for i in 0..<points.count {
            let current = points[i]
            let next = points[(i + 1) % points.count]
            
            var path = Path()
            path.move(to: current)
            
            // Create smooth curve
            let controlPoint1 = CGPoint(
                x: current.x + (next.x - current.x) / 3,
                y: current.y + (next.y - current.y) / 3
            )
            let controlPoint2 = CGPoint(
                x: current.x + (next.x - current.x) * 2 / 3,
                y: current.y + (next.y - current.y) * 2 / 3
            )
            
            path.addCurve(
                to: next,
                control1: controlPoint1,
                control2: controlPoint2
            )
            
            context.stroke(path, with: .color(color), lineWidth: 1)
        }
    }
    
    // MARK: - Helper Functions
    
    private func drawHexagonNode(
        at center: CGPoint,
        radius: CGFloat,
        context: inout GraphicsContext,
        color: Color
    ) {
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
        
        context.stroke(
            path,
            with: .color(color),
            lineWidth: 0.5
        )
    }
    
    private func generateOrganicPoints(
        in rect: CGRect,
        count: Int
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = min(rect.width, rect.height) / 3
        
        for i in 0..<count {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(count)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
}

// MARK: - Wrapper for use in Views

struct WithNeuralPathway<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    
    let content: Content
    let style: NeuralPathwayBackground.PathwayStyle
    
    init(
        style: NeuralPathwayBackground.PathwayStyle = .hexagonal,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
    }
    
    var body: some View {
        ZStack {
            // Background gradient with neural pathways
            LinearGradient(
                gradient: Gradient(colors: [theme.gradientStart, theme.gradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NeuralPathwayBackground(opacity: 0.15, style: style)
                .ignoresSafeArea()
            
            content
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        // Linear preview
        WithNeuralPathway(style: .linear) {
            VStack {
                Text("Linear Pathways")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 200)
        
        // Hexagonal preview
        WithNeuralPathway(style: .hexagonal) {
            VStack {
                Text("Hexagonal Network")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 200)
        
        // Organic preview
        WithNeuralPathway(style: .organic) {
            VStack {
                Text("Organic Pathways")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 200)
    }
    .environmentObject(ThemeManager())
}
