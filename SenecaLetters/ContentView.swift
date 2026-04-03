//
//  ContentView.swift
//  SenecaLetters
//

import SwiftUI

struct ContentView: View {
    /// Single source of truth for auth state, outlives both AuthView and MainTabView.
    @State private var apiClient = APIClient()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        // APIClient is @Observable — SwiftUI re-renders automatically when
        // isAuthenticated changes, no manual onChange needed.
        Group {
            if apiClient.isAuthenticated {
                MainTabView(apiClient: apiClient)
            } else {
                AuthView(viewModel: AuthViewModel(apiClient: apiClient))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
