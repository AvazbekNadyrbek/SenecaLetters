//
//  ThemeTag.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/17/26.
//

import SwiftUI

struct ThemeTagButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? Constants.Colors.accent
                    : Color(.systemGray6)
            )
            .foregroundStyle(
                isSelected
                    ? Constants.Colors.accentLight
                    : .secondary
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ThemeTag: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(name)
        }
        .buttonStyle(ThemeTagButtonStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel("\(name) theme tag")
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
    }
}

#Preview {
    ThemeTag(name: "Test", isSelected: false, action: {})
}
