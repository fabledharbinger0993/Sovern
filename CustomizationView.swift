import SwiftUI

// MARK: - CustomizationView

/// User customization screen for setting name and initial values
struct CustomizationView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var userName = ""
    @State private var selectedValues: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    let availableValues = [
        "Authenticity",
        "Growth",
        "Curiosity",
        "Empathy",
        "Integrity",
        "Understanding",
        "Creativity",
        "Honesty",
        "Respect",
        "Wisdom",
        "Trust",
        "Balance"
    ]
    
    var canContinue: Bool {
        !userName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedValues.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.gradientStart,
                    themeManager.gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Let's Get to Know Each Other")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(themeManager.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Share a name and your core values")
                            .font(.body)
                            .foregroundStyle(themeManager.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Name", systemImage: "person.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(themeManager.textPrimary)
                        
                        TextField("What should I call you?", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .padding(12)
                            .background(themeManager.cardBackground)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Values Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Core Values", systemImage: "star.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(themeManager.textPrimary)
                        
                        Text("Select at least 2 values that matter most to you")
                            .font(.caption)
                            .foregroundStyle(themeManager.textSecondary)
                        
                        // Values Grid
                        VStack(spacing: 10) {
                            ForEach(0..<((availableValues.count + 2) / 3), id: \.self) { row in
                                HStack(spacing: 10) {
                                    ForEach(0..<3, id: \.self) { col in
                                        let index = row * 3 + col
                                        if index < availableValues.count {
                                            let value = availableValues[index]
                                            Button(action: {
                                                if selectedValues.contains(value) {
                                                    selectedValues.remove(value)
                                                } else {
                                                    if selectedValues.count < 5 {
                                                        selectedValues.insert(value)
                                                    }
                                                }
                                            }) {
                                                Text(value)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(
                                                        selectedValues.contains(value) ?
                                                        .white : themeManager.textPrimary
                                                    )
                                                    .frame(maxWidth: .infinity)
                                                    .padding(10)
                                                    .background(
                                                        selectedValues.contains(value) ?
                                                        themeManager.accentPrimary :
                                                        themeManager.cardBackground
                                                    )
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(
                                                                selectedValues.contains(value) ?
                                                                themeManager.accentPrimary :
                                                                themeManager.borderColor,
                                                                lineWidth: 1.5
                                                            )
                                                    )
                                            }
                                        } else {
                                            Color.clear
                                        }
                                    }
                                }
                            }
                        }
                        
                        if selectedValues.count > 0 {
                            Text("\(selectedValues.count) of 5 selected (max)")
                                .font(.caption2)
                                .foregroundStyle(themeManager.textSecondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if showError {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                
                                Spacer()
                            }
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: continueToChat) {
                        Text("Continue to Chat")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        canContinue ? themeManager.accentPrimary : themeManager.accentPrimary.opacity(0.5),
                                        canContinue ? themeManager.accentPrimary.opacity(0.8) : themeManager.accentPrimary.opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .disabled(!canContinue)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }
    
    private func continueToChat() {
        let trimmedName = userName.trimmingCharacters(in: .whitespaces)
        
        // Validation
        if trimmedName.isEmpty {
            showError = true
            errorMessage = "Please enter your name"
            return
        }
        
        if selectedValues.isEmpty {
            showError = true
            errorMessage = "Please select at least one value"
            return
        }
        
        // Create user context
        let context = UserRelationalContext(
            name: trimmedName,
            coreValues: Array(selectedValues)
        )
        
        // Save and advance
        coordinator.setUserContext(context)
        
        withAnimation {
            coordinator.currentScreen = .chat
        }
    }
}

#Preview {
    CustomizationView()
        .environmentObject(AppCoordinator())
        .environmentObject(ThemeManager())
}
