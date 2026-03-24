//
//  AuthView.swift
//  SenecaLetters
//

import SwiftUI

struct AuthView: View {

    @Bindable var viewModel: AuthViewModel
    @State private var isSheetPresented: Bool = true
    
    var body: some View {
        ZStack() {
            // Background image
            Image("SenecaFrameImg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay {
                    // Subtle gradient for depth
                    LinearGradient(
                        colors: [.black.opacity(0.4), .black.opacity(0.1)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea()
                }
        }
        .sheet(isPresented: $isSheetPresented) {
            authSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
        .background(.black)
    }
    
    // MARK: - Auth Sheet Content
    
    private var authSheet: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                header
                formFields
                submitButton
                toggleModeButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Seneca Letters")
                .font(Constants.Fonts.serifBold(26))
                .foregroundStyle(Constants.Colors.accent)

            Text(viewModel.isLoginMode ? "Welcome back" : "Create an account")
                .font(Constants.Fonts.serif(15))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            AuthField(label: "Username", text: $viewModel.username)

            if !viewModel.isLoginMode {
                AuthField(
                    label: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            AuthField(label: "Password", text: $viewModel.password, isSecure: true)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLoginMode)
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.isLoginMode ? "Log In" : "Sign Up")
                        .font(Constants.Fonts.serifBold(16))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Constants.Colors.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Constants.Colors.accent.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(viewModel.isLoading)
    }

    private var toggleModeButton: some View {
        Button {
            viewModel.toggleMode()
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.isLoginMode ? "Don't have an account?" : "Already have an account?")
                    .foregroundStyle(.gray)
                Text(viewModel.isLoginMode ? "Sign Up" : "Log In")
                    .fontWeight(.semibold)
                    .foregroundStyle(Constants.Colors.accent)
            }
            .font(Constants.Fonts.serif(14))
        }
    }
}

// MARK: - Reusable field component

private struct AuthField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Constants.Fonts.serif(12))
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(apiClient: APIClient()))
}
