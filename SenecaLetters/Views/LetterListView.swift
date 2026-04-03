//
//  LetterListView.swift
//  SenecaLetters
//

import SwiftUI

struct LetterListView: View {
    @Bindable var viewModel: LetterListViewModel
    @AppStorage("isDarkMode")   private var isDarkMode = false
    @AppStorage("readerTheme")  private var rawTheme: String = Constants.ReaderTheme.light.rawValue

    var body: some View {
        NavigationStack {
            List {
                // Theme filter strip
                if !viewModel.allThemes.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.allThemes, id: \.self) { theme in
                                ThemeTag(
                                    name: theme,
                                    isSelected: viewModel.selectedTheme == theme,
                                    action: { viewModel.toggleTheme(theme) }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                }

                // Letters
                ForEach(viewModel.filteredLetters) { letter in
                    NavigationLink(value: letter) {
                        LetterRow(letter: letter)
                    }
                }
            }
            .navigationTitle("Cенека")
            .navigationSubtitle("126 писем")
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: toggleDarkMode) {
                        Label(
                            isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
                            systemImage: isDarkMode ? "sun.max.fill" : "moon.fill"
                        )
                    }
                    .foregroundStyle(isDarkMode ? .white : .primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Profile", systemImage: "person.circle") { }
                        .foregroundStyle(isDarkMode ? .white : .primary)
                }
            }
            .navigationDestination(for: Letter.self) { letter in
                ReaderView(letter: letter)
            }
            .overlay {
                if viewModel.isLoading && viewModel.letters.isEmpty {
                    ProgressView()
                }
                if let error = viewModel.errorMessage, viewModel.letters.isEmpty {
                    ContentUnavailableView {
                        Label("Connection error", systemImage: "wifi.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try again") {
                            Task { await viewModel.loadLetters() }
                        }
                    }
                }
            }
            .task {
                if viewModel.letters.isEmpty {
                    await viewModel.loadLetters()
                }
            }
            .refreshable {
                await viewModel.loadLetters()
            }
        }
    }

    private func toggleDarkMode() {
        isDarkMode.toggle()
        if isDarkMode {
            rawTheme = Constants.ReaderTheme.dark.rawValue
        } else if rawTheme == Constants.ReaderTheme.dark.rawValue {
            rawTheme = Constants.ReaderTheme.light.rawValue
        }
    }
}
