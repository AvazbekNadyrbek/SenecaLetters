//
//  MiniPlayerView.swift
//  SenecaLetters
//

import SwiftUI

struct MiniPlayerView: View {
    var audioService: AudioService

    var body: some View {
        HStack(spacing: 15) {
            playerInfo(.init(width: 36, height: 36))

            Spacer(minLength: 0)

            // Play / Pause
            Button {
                audioService.togglePlayPause()
            } label: {
                Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .contentShape(.rect)
            }
            .padding(.trailing, 10)

            // Forward (skip 15s)
            Button {
                audioService.seek(to: min(1, audioService.progress + 15 / max(audioService.duration, 1)))
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
                    .contentShape(.rect)
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }

    // MARK: - Reusable Player Info

    @ViewBuilder
    func playerInfo(_ size: CGSize) -> some View {
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
                    .foregroundStyle(.gray)
//
//                GeometryReader { geo in
//                    ZStack(alignment: .leading) {
//                        Capsule()
//                            .fill(Color(.systemGray5))
//                            .frame(height: 2)
//                        Capsule()
//                            .fill(Constants.Colors.accent)
//                            .frame(width: geo.size.width * audioService.progress, height: 2)
//                    }
//                }
//                .frame(height: 2)
            }
        }
    }
}
