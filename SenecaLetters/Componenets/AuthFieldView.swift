//
//  AuthFieldView.swift
//  SenecaLetters
//

import SwiftUI

/// A labelled text / secure field used in the authentication form.
struct AuthFieldView: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Constants.Fonts.serif(12, relativeTo: .caption))
                .foregroundStyle(.secondary)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Constants.Colors.accentLight.opacity(0.35))
            .clipShape(.rect(cornerRadius: 10))
        }
    }
}
