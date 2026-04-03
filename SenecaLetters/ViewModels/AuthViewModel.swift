//
//  AuthViewModel.swift
//  SenecaLetters
//

import Foundation
import AuthenticationServices

// @Observable — iOS 17+ macro. The view automatically re-renders when any
// stored property changes. No need for @Published on every field.
//
// @MainActor — all UI state must be updated on the main thread.
// By marking the whole class @MainActor we get that guarantee for free.
@Observable
@MainActor
class AuthViewModel {

    // MARK: - Form state (two-way bound to the view)
    var username = ""
    var password = ""
    var email = ""          // only used during sign-up

    // MARK: - UI state
    var isLoading = false
    var errorMessage: String?
    var isLoginMode = true  // true = login form, false = sign-up form

    // MARK: - Dependency
    // The VM doesn't create its own APIClient — it receives one from outside.
    // This is called "dependency injection". It makes the VM testable and
    // keeps the APIClient instance shared across the whole app.
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Actions

    // One method handles both login and sign-up — the view just calls submit().
    func submit() async {
        guard validate() else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }   // always runs when the function exits

        do {
            if isLoginMode {
                try await apiClient.login(username: username, password: password)
                // APIClient.isAuthenticated becomes true → ContentView switches to MainTabView
            } else {
                try await apiClient.register(username: username, email: email, password: password)
                // After sign-up, auto-login with the same credentials
                try await apiClient.login(username: username, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil      // clear errors when switching modes
    }

    // MARK: - Sign In with Apple

    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple Sign In failed: missing credentials"
                return
            }

            let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            do {
                try await apiClient.authenticateWithApple(
                    identityToken: identityToken,
                    userIdentifier: credential.user,
                    email: credential.email,
                    fullName: nameParts.isEmpty ? nil : nameParts
                )
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            // User cancelled the sheet — not an error worth showing
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Private helpers

    private func validate() -> Bool {
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Username is required"
            return false
        }
        if password.count < 4 {
            errorMessage = "Password must be at least 4 characters"
            return false
        }
        if !isLoginMode && !email.contains("@") {
            errorMessage = "Please enter a valid email"
            return false
        }
        return true
    }
}
