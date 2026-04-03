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
                            QuoteRowView(quote: quote)
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
}

// MARK: - Quote Row

private struct QuoteRowView: View {
    let quote: SavedQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quote.text)
                .font(Constants.Fonts.serif(15, relativeTo: .callout))
                .lineLimit(4)
                .foregroundStyle(.primary)

            Text("Letter \(quote.letterNumber) · \(quote.letterTitle)")
                .font(.footnote)
                .foregroundStyle(Constants.Colors.accent)
        }
        .padding(.vertical, 4)
    }
}
