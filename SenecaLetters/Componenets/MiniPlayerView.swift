//
//  MiniPlayerView.swift
//  SenecaLetters
//

import SwiftUI

struct MiniPlayerView: View {
    let letterTitle: String
    var audioService: AudioService
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 14) {
                // Play/Pause — своя кнопка, onTap не мешает
                Button { audioService.togglePlayPause() } label: {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.accent)
                            .frame(width: 40, height: 40)
                        Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Constants.Colors.accentLight)
                            .offset(x: audioService.isPlaying ? 0 : 1)
                    }
                }

                // Название + прогресс — нажатие открывает полный плеер
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(letterTitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(audioService.currentTimeFormatted)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 3)
                                Capsule()
                                    .fill(Constants.Colors.accent)
                                    .frame(width: geo.size.width * audioService.progress, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)

                // Скорость — своя кнопка
                Button { audioService.cycleSpeed() } label: {
                    Text(String(format: "%.2gx", audioService.playbackRate))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Constants.Colors.accent)
                        .frame(width: 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
}
