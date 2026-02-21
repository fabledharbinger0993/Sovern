import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode = false // Light mode is default
    
    // MARK: - Dark Mode Colors
    let darkBase = Color(red: 0.0, green: 0.0, blue: 0.0)
    let darkCharcoal = Color(red: 0.15, green: 0.15, blue: 0.18)
    let darkPurple = Color(red: 0.25, green: 0.15, blue: 0.35)
    let darkBlue = Color(red: 0.1, green: 0.2, blue: 0.35)
    let darkGray = Color(red: 0.3, green: 0.3, blue: 0.35)
    let electricOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    let silver = Color(red: 0.9, green: 0.9, blue: 0.92)
    
    // MARK: - Light Mode Colors
    let lightBase = Color(red: 1.0, green: 1.0, blue: 1.0)
    let lightPaleYellow = Color(red: 1.0, green: 0.98, blue: 0.90)
    let lightLavender = Color(red: 0.92, green: 0.88, blue: 0.98)
    let darkGold = Color(red: 0.7, green: 0.55, blue: 0.2)
    let darkNavy = Color(red: 0.1, green: 0.1, blue: 0.2)
    
    // MARK: - Adaptive Colors
    var background: Color {
        isDarkMode ? darkBase : lightBase
    }
    
    var cardBackground: Color {
        isDarkMode ? darkCharcoal.opacity(0.3) : lightPaleYellow.opacity(0.5)
    }
    
    var textPrimary: Color {
        isDarkMode ? silver : darkNavy
    }
    
    var textSecondary: Color {
        isDarkMode ? darkGray : darkGold
    }
    
    var accentPrimary: Color {
        isDarkMode ? electricOrange : darkGold
    }
    
    var accentSecondary: Color {
        isDarkMode ? silver : lightLavender
    }
    
    var borderColor: Color {
        isDarkMode ? silver.opacity(0.3) : darkGold.opacity(0.4)
    }
    
    var gradientStart: Color {
        isDarkMode ? 
            darkBase :
            lightPaleYellow
    }
    
    var gradientEnd: Color {
        isDarkMode ?
            darkPurple :
            lightLavender
    }
    
    var heartColor: Color {
        isDarkMode ? electricOrange : lightLavender
    }
    
    var logicButtonColor: Color {
        isDarkMode ? electricOrange : darkGold
    }
    
    var memoryButtonColor: Color {
        isDarkMode ? silver : lightLavender
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
}
