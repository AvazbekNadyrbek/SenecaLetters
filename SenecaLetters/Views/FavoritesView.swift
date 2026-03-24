//
//  FavoritesView.swift
//  SenecaLetters
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    let letters: [Letter]

    @Query(sort: \FavoriteLetter.savedAt, order: .reverse) private var favorites: [FavoriteLetter]
    @Environment(\.modelContext) private var modelContext

    private var favoriteLetters: [Letter] {
        let ids = Set(favorites.map { $0.letterId })
        return letters.filter { ids.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteLetters.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart in any letter to save it here.")
                    )
                } else {
                    List {
                        ForEach(favoriteLetters) { letter in
                            NavigationLink(value: letter) {
                                LetterRow(letter: letter)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                let letterId = favoriteLetters[i].id
                                if let match = favorites.first(where: { $0.letterId == letterId }) {
                                    modelContext.delete(match)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(for: Letter.self) { letter in
                ReaderView(letter: letter)
            }
        }
    }
}
