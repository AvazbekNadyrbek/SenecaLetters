//
//  LetterRow.swift
//  SenecaLetters
//

import SwiftUI

struct LetterRow: View {

    let letter: Letter
    @Environment(DownloadService.self) private var downloadService

    private var romanNumber: String {
        let romans = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                      "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]
        let number = letter.number
        if number > 0 && number < romans.count {
            return romans[number]
        }
        return "\(number)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Roman numeral
            Text(romanNumber)
                .font(.custom("Georgia", size: 22, relativeTo: .title3))
                .fontWeight(.medium)
                .foregroundStyle(Constants.Colors.accent)
                .frame(minWidth: 32, alignment: .leading)

            // Title + summary
            VStack(alignment: .leading, spacing: 3) {
                Text(letter.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let summary = letter.summary {
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Audio / download status badge — only for letters that have audio
            if letter.audioUrl != nil {
                AudioStatusBadge(
                    letterId: letter.id,
                    downloadService: downloadService
                )
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Audio Status Badge

/// Shows audio availability and offline download state at a glance.
private struct AudioStatusBadge: View {
    let letterId: Int
    let downloadService: DownloadService

    var body: some View {
        Group {
            if downloadService.isActive(letterId: letterId) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Constants.Colors.accent)
            } else if downloadService.isDownloaded(letterId: letterId) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Constants.Colors.accent)
                    .font(.footnote)
            } else {
                Image(systemName: "waveform")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: downloadService.isActive(letterId: letterId))
        .animation(.easeInOut(duration: 0.2), value: downloadService.isDownloaded(letterId: letterId))
    }
}
