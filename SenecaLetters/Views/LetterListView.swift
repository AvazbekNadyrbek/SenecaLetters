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
                // Фильтр по темам
                if !viewModel.allThemes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
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
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                }

                // Письма
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
                    Button {
                        isDarkMode.toggle()
                        // Sync reading theme: dark mode on → dark theme; off → restore light
                        if isDarkMode {
                            rawTheme = Constants.ReaderTheme.dark.rawValue
                        } else if rawTheme == Constants.ReaderTheme.dark.rawValue {
                            rawTheme = Constants.ReaderTheme.light.rawValue
                        }
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundStyle(isDarkMode ? .white : .primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(isDarkMode ? .white : .primary)
                    }
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
    
    // MARK: - Helper Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private var userInitials: String {
        // TODO: Get from actual user profile when available
        // For now, return a placeholder
        return "ME"
    }
}
