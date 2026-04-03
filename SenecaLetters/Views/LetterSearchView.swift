//
//  LetterSearchView.swift
//  SenecaLetters
//

import SwiftUI

/// The search tab — uses the native iOS search tab role so the search
/// field appears inline at the top of the tab bar area.
struct LetterSearchView: View {
    @Bindable var viewModel: LetterListViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredLetters) { letter in
                    NavigationLink(value: letter) {
                        LetterRow(letter: letter)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .searchable(text: $viewModel.searchText, prompt: "Search letters")
            .navigationDestination(for: Letter.self) { letter in
                ReaderView(letter: letter)
            }
            .overlay {
                if !viewModel.searchText.isEmpty && viewModel.filteredLetters.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
            .task {
                if viewModel.letters.isEmpty {
                    await viewModel.loadLetters()
                }
            }
        }
    }
}
