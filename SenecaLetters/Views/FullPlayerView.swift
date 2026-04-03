//
//  FullPlayerView.swift
//  SenecaLetters
//

import SwiftUI

struct FullPlayerView: View {
    var audioService: AudioService

    var body: some View {
        ScrollView {
            // ScrollView body — заменить Text("Hello") на:
            VStack(spacing: 20) {
                Text(audioService.currentLetterSubtitle)
                    .font(Constants.Fonts.serif(16, relativeTo: .body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            PlayerHeaderView(audioService: audioService)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

// MARK: - Player Header

private struct PlayerHeaderView: View {
    var audioService: AudioService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {

            // Drag indicator — tap to dismiss
            Button("Dismiss player") { dismiss() }
                .buttonStyle(.plain)
                .frame(height: 20)
                .frame(maxWidth: .infinity)
                .overlay {
                    Capsule()
                        .fill(.primary.secondary)
                        .frame(width: 35, height: 3)
                }
                .padding(.top, 12)

            // Cover art + title + action buttons
            HStack(spacing: 0) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Constants.Colors.accentLight)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "scroll")
                                .font(.system(size: 32))
                                .foregroundStyle(Constants.Colors.accent.opacity(0.5))
                        }
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(audioService.currentLetterTitle)
                            .font(Constants.Fonts.serifBold(20, relativeTo: .title3))
                            .lineLimit(1)
                        Text("Seneca")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Group {
                    Button("Favorite", systemImage: "heart.circle.fill") { }
                    Button("More options", systemImage: "ellipsis.circle.fill") { }
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .foregroundStyle(Color.primary, Color.primary.opacity(0.1))
            }
            .padding(.horizontal, 15)

            // Progress bar with drag gesture
            ProgressBarView(audioService: audioService)
                .padding(.horizontal, 24)

            // Controls: skip back / play-pause / skip forward
            PlaybackControlsView(audioService: audioService)
                .padding(.vertical, 8)

            // Playback speed
            Button {
                audioService.cycleSpeed()
            } label: {
                Text("\(audioService.playbackRate.formatted(.number.precision(.fractionLength(0...2))))×")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Constants.Colors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.accentLight)
                    .clipShape(.capsule)
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBarView: View {
    var audioService: AudioService

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)
                    Capsule()
                        .fill(Constants.Colors.accent)
                        .frame(width: geo.size.width * audioService.progress, height: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            audioService.seek(to: max(0, min(1, value.location.x / geo.size.width)))
                        }
                )
            }
            .frame(height: 4)

            HStack {
                Text(audioService.currentTimeFormatted)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(audioService.durationFormatted)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Playback Controls

private struct PlaybackControlsView: View {
    var audioService: AudioService

    var body: some View {
        HStack(spacing: 52) {
            Button("Skip back 15 seconds", systemImage: "gobackward.15") {
                audioService.seek(to: max(0, audioService.progress - 15 / max(audioService.duration, 1)))
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 28))
            .foregroundStyle(.primary)

            Button {
                audioService.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Constants.Colors.accent)
                        .frame(width: 72, height: 72)
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Constants.Colors.accentLight)
                        .offset(x: audioService.isPlaying ? 0 : 2)
                }
            }
            .accessibilityLabel(audioService.isPlaying ? "Pause" : "Play")

            Button("Skip forward 15 seconds", systemImage: "goforward.15") {
                audioService.seek(to: min(1, audioService.progress + 15 / max(audioService.duration, 1)))
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 28))
            .foregroundStyle(.primary)
        }
    }
}

