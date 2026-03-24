//
//  QuotesView.swift
//  SenecaLetters
//

import SwiftUI
import SwiftData

struct QuotesView: View {
    @Query(sort: \SavedQuote.savedAt, order: .reverse) var quotes: [SavedQuote]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if quotes.isEmpty {
                    ContentUnavailableView(
                        "No Quotes Yet",
                        systemImage: "quote.bubble",
                        description: Text("Long press any paragraph in a letter to save a quote.")
                    )
                } else {
                    List {
                        ForEach(quotes) { quote in
                            quoteRow(quote)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { modelContext.delete(quotes[$0]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Quotes")
        }
    }

    private func quoteRow(_ quote: SavedQuote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quote.text)
                .font(Constants.Fonts.serif(15))
                .lineLimit(4)
                .foregroundStyle(.primary)

            Text("Letter \(quote.letterNumber) · \(quote.letterTitle)")
                .font(.system(size: 12))
                .foregroundStyle(Constants.Colors.accent)
        }
        .padding(.vertical, 4)
    }
}
