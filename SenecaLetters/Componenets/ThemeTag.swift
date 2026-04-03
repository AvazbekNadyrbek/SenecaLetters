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
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? Constants.Colors.accent
                    : Color.secondary.opacity(0.15)
            )
            .foregroundStyle(
                isSelected
                    ? Constants.Colors.accentLight
                    : .secondary
            )
            .clipShape(.capsule)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ThemeTag: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    @State private var feedbackTrigger = false

    var body: some View {
        Button {
            feedbackTrigger.toggle()
            action()
        } label: {
            Text(name)
        }
        .buttonStyle(ThemeTagButtonStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel("\(name) theme tag")
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: feedbackTrigger)
    }
}

#Preview {
    ThemeTag(name: "Test", isSelected: false, action: {})
}
