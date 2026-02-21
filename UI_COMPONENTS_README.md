# Sovern UI Component System

Complete SwiftUI component library for the Sovern cognitive agent interface with:
- Adaptive light/dark theme system
- Hexagon-shaped buttons and navigation
- Transparent cards with frame styling
- Neural pathway background patterns
- Color-coded tab system

## Components

### 1. ThemeManager
Centralized theme management for light/dark mode with color adaptation.

**Usage:**
```swift
@EnvironmentObject var theme: ThemeManager

// Toggle dark mode
theme.toggleDarkMode()

// Use adaptive colors
Rectangle()
    .fill(theme.background)
    .border(theme.borderColor, width: 1)
```

**Color System:**
- **Dark Mode**: Black, charcoal, deep purple/blue + electric orange accents + silver UI
- **Light Mode** (default): White, pale yellow, lavender + dark gold accents

**Adaptive Colors:**
- `background` - Main background
- `cardBackground` - Transparent card backgrounds
- `textPrimary` / `textSecondary` - Text colors
- `accentPrimary` / `accentSecondary` - Accent colors
- `borderColor` - Frame/border colors
- `heartColor` - Logo color (orange/lavender toggle)
- `logicButtonColor` - Logic tab accent
- `memoryButtonColor` - Memory tab accent

---

### 2. HexagonButton
Reusable hexagon-shaped button component with icon and text.

**Features:**
- 6-sided polygon shape
- Three size options: small (~24pt), medium (~40pt), large (~60pt)
- Color variants: logic, memory, neutral
- Adaptive colors based on theme

**Usage:**
```swift
HexagonButton(
    title: "Logic",
    icon: "brain.head.profile",
    size: .medium,
    color: .logic
) {
    // Action
}
```

**Properties:**
- `title` - Button label (optional)
- `icon` - SF Symbol name (optional)
- `size` - `.small`, `.medium`, or `.large`
- `color` - `.logic` (orange), `.memory` (lavender), or `.neutral`
- `action` - Closure on tap

---

### 3. TransparentCard
Reusable transparent card component with optional frame styling.

**Features:**
- Transparent background with blur effect
- Customizable border colors (gold, silver, or adaptive)
- Rounded or hexagonal corners
- Multiple card types for common use cases

**Generic Usage:**
```swift
TransparentCard {
    Text("Card content here")
        .foregroundStyle(theme.textPrimary)
}
```

**Convenience Initializers:**

```swift
// Frame-styled card
TransparentCard(frameStyle: .gold) {
    Text("Gold frame card")
}

// Message bubble
MessageCard(message: "Hello", isUser: true)

// Insight card (with sparkles for profound insights)
InsightCard(
    title: "Key Insight",
    content: "Details about the insight",
    isProfound: true
)

// Belief card with weight bar
BeliefCard(
    stance: "Authenticity",
    weight: 9,
    domain: "ETHICS",
    isCore: true
)
```

---

### 4. NeuralPathwayBackground
Subtle animated background pattern with three styles.

**Features:**
- Three pathway styles: linear, hexagonal, organic
- Subtle opacity (10-20%)
- Adapts to theme colors
- Texture adds visual depth without distraction

**Usage:**
```swift
// Standalone
NeuralPathwayBackground(opacity: 0.15, style: .hexagonal)
    .ignoresSafeArea()

// Wrapped with gradient background
WithNeuralPathway(style: .hexagonal) {
    // Content view
}
```

**Pathway Styles:**
- `.linear` - Diagonal straight lines
- `.hexagonal` - Connected hexagon nodes
- `.organic` - Curved connecting paths

---

### 5. SovernTabNavigationView
Complete 5-tab navigation system with color-coded tabs and neural pathway background.

**Features:**
- 5 tabs: Chat, Logic, Memory, Beliefs, Settings
- Hexagon buttons at bottom with label
- Orange accents for Logic tab
- Lavender accents for Memory tab
- Heart logo toggles dark/light mode
- Neural pathway background on all views

**Included Tab Views:**
- **ChatTabView** - Message interface
- **LogicTabView** - Congress debates and reasoning
- **MemoryTabView** - Human vs. Self insights
- **BeliefsTabView** - Weighted belief hexagons
- **SettingsTabView** - Theme toggle and config

**Usage in App:**
```swift
@main
struct SovernApp: App {
    @StateObject private var theme = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            SovernTabNavigationView()
                .environmentObject(theme)
        }
    }
}
```

---

## Integration Guide

### 1. Set Up ThemeManager in App
```swift
@main
struct SovernApp: App {
    @StateObject private var theme = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(theme)
        }
    }
}
```

### 2. Use Components in Your Views
```swift
struct MyView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack {
            // Hexagon button
            HexagonButton(
                title: "Action",
                icon: "checkmark.circle",
                size: .medium,
                color: .logic
            ) {
                // Do something
            }
            
            // Card with content
            TransparentCard {
                VStack {
                    Text("Important Information")
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                }
            }
            
            // Text with adaptive colors
            Text("This adjusts automatically to light/dark mode")
                .foregroundStyle(theme.textSecondary)
        }
        .background(theme.background)
    }
}
```

### 3. Create Custom Cards
```swift
// Create new card types by extending TransparentCard
struct CustomCard: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        TransparentCard(
            borderColor: theme.darkGold.opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Card")
                    .font(.headline)
                    .foregroundStyle(theme.accentPrimary)
            }
        }
    }
}
```

---

## Color Reference

### Dark Mode
- **Base**: Black (`#000000`)
- **Charcoal**: `rgb(38, 38, 46)`
- **Purple**: `rgb(64, 38, 89)`
- **Blue**: `rgb(26, 51, 89)`
- **Orange** (Logic): `rgb(255, 128, 0)` ← Primary accent
- **Silver**: `rgb(230, 230, 235)` ← Text & frames

### Light Mode (Default)
- **White**: `#FFFFFF`
- **Pale Yellow**: `rgb(255, 250, 230)`
- **Lavender** (Memory): `rgb(235, 224, 250)` ← Component accent
- **Dark Gold** (Text/Frames): `rgb(179, 140, 51)`
- **Dark Navy** (Primary text): `rgb(26, 26, 51)`

---

## Customization

### Change Default Theme
```swift
// In ThemeManager init or app startup
let theme = ThemeManager()
theme.isDarkMode = true // Set dark mode as default
```

### Extend ThemeManager
```swift
extension ThemeManager {
    // Add custom colors
    var customGreen: Color {
        isDarkMode ? Color(red: 0.2, green: 0.6, blue: 0.4) : Color(red: 0.7, green: 1.0, blue: 0.8)
    }
}
```

### Customize Hexagon Size
```swift
enum HexagonSize {
    case extra_small // ~16pt
    case small       // ~24pt
    case medium      // ~40pt
    case large       // ~60pt
}
```

---

## File Structure

```
Sovern/
├── ThemeManager.swift              # Color system & theme switching
├── HexagonButton.swift             # Hexagon button & shape
├── TransparentCard.swift           # Card components (generic + specific types)
├── NeuralPathwayBackground.swift   # Background patterns
└── SovernTabNavigationView.swift   # 5-tab navigation system
```

---

## Tips

1. **Always use `@EnvironmentObject var theme`** Not just for colors, but to ensure all views respond to theme changes instantly.

2. **Keep Neural Pathway opacity low** (10-20%) so it doesn't distract from content.

3. **Use color-coded buttons strategically**:
   - Orange for Logic/analytical actions
   - Lavender for Memory/relational actions
   - Neutral for other navigation

4. **Message bubbles should always have frames** (use `MessageCard`) for readability over gradient backgrounds.

5. **Test in both light and dark mode** before finalizing any custom components.

---

## Future Enhancements

- [ ] Animation support for hexagon button hover states
- [ ] Animated neural pathways (moving/pulsing)
- [ ] Custom hexagon clipping for cards
- [ ] Gesture recognition for swipe-based navigation
- [ ] Voice indicator animation during thinking
- [ ] Belief hexagon node interaction (tap, drag, zoom)
