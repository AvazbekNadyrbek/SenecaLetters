//
//  AuthView.swift
//  SenecaLetters
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {

    @Bindable var viewModel: AuthViewModel
    @State private var isSheetPresented: Bool = true

    var body: some View {
        ZStack {
            // Background image
            Image("SenecaFrameImg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.4), .black.opacity(0.1)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea()
                }
        }
        .sheet(isPresented: $isSheetPresented) {
            AuthSheetView(viewModel: viewModel)
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.hidden)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
        .background(.black)
    }
}

// MARK: - Auth Sheet

private struct AuthSheetView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                AuthHeaderView(viewModel: viewModel)
                AuthFormFieldsView(viewModel: viewModel)
                AuthSubmitButton(viewModel: viewModel)
                AuthToggleModeButton(viewModel: viewModel)
                AppleSignInSection(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Auth Header

private struct AuthHeaderView: View {
    let viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Seneca Letters")
                .font(Constants.Fonts.serifBold(26, relativeTo: .title))
                .foregroundStyle(Constants.Colors.accent)

            Text(viewModel.isLoginMode ? "Welcome back" : "Create an account")
                .font(Constants.Fonts.serif(15, relativeTo: .callout))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Auth Form Fields

private struct AuthFormFieldsView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 14) {
            AuthFieldView(label: "Username", text: $viewModel.username)

            if !viewModel.isLoginMode {
                AuthFieldView(
                    label: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            AuthFieldView(label: "Password", text: $viewModel.password, isSecure: true)

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
}

// MARK: - Submit Button

private struct AuthSubmitButton: View {
    let viewModel: AuthViewModel

    var body: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.isLoginMode ? "Log In" : "Sign Up")
                        .font(Constants.Fonts.serifBold(16, relativeTo: .callout))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Constants.Colors.accent)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: Constants.Colors.accent.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - Toggle Mode Button

private struct AuthToggleModeButton: View {
    let viewModel: AuthViewModel

    var body: some View {
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
            .font(Constants.Fonts.serif(14, relativeTo: .footnote))
        }
    }
}

// MARK: - Apple Sign In Section

private struct AppleSignInSection: View {
    let viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().fill(.separator).frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                Rectangle().fill(.separator).frame(height: 1)
            }

            SignInWithAppleButton(viewModel.isLoginMode ? .signIn : .signUp) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await viewModel.signInWithApple(result: result) }
            }
            .frame(height: 50)
            .clipShape(.rect(cornerRadius: 12))
            .id(viewModel.isLoginMode)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLoginMode)
        }
        .padding(.top, 4)
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(apiClient: APIClient()))
}
