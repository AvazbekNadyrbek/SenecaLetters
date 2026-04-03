//
//  MiniPlayerView.swift
//  SenecaLetters
//

import SwiftUI

struct MiniPlayerView: View {
    var audioService: AudioService

    var body: some View {
        HStack(spacing: 15) {
            PlayerInfoView(audioService: audioService, size: .init(width: 36, height: 36))

            Spacer(minLength: 0)

            // Play / Pause
            Button("Play or Pause", systemImage: audioService.isPlaying ? "pause.fill" : "play.fill") {
                audioService.togglePlayPause()
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .contentShape(.rect)
            .padding(.trailing, 10)

            // Forward (skip 15 s)
            Button("Skip forward 15 seconds", systemImage: "forward.fill") {
                audioService.seek(to: min(1, audioService.progress + 15 / max(audioService.duration, 1)))
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .contentShape(.rect)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }
}

// MARK: - Player Info

private struct PlayerInfoView: View {
    let audioService: AudioService
    let size: CGSize

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: size.height / 4)
                .fill(Constants.Colors.accentLight)
                .frame(width: size.width, height: size.height)
                .overlay {
                    Image(systemName: "scroll")
                        .font(.system(size: size.height * 0.42))
                        .foregroundStyle(Constants.Colors.accent)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(audioService.currentLetterSubtitle)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(audioService.currentLetterTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
