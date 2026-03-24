//
//  FullPlayerView.swift
//  SenecaLetters
//

import SwiftUI

struct FullPlayerView: View {
    var audioService: AudioService
    var animation: Namespace.ID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack {
                Text("Hello")
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            playerHeader
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .modifier(ZoomTransition(id: "MINIPLAYER", animation: animation))
    }

    // MARK: - Верхняя часть (drag indicator + обложка + контролы)

    private var playerHeader: some View {
        VStack(spacing: 10) {

            // Drag indicator (как в тесте)
            Capsule()
                .fill(.primary.secondary)
                .frame(width: 35, height: 3)
                .padding(.top, 12)

            // Обложка + заголовок + action buttons (как PlayerInfo в тесте)
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
                            .font(Constants.Fonts.serifBold(20))
                            .lineLimit(1)
                        Text("Seneca")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Action buttons (как в тесте)
                Group {
                    Button("", systemImage: "heart.circle.fill") { }
                    Button("", systemImage: "ellipsis.circle.fill") { }
                }
                .font(.title)
                .foregroundStyle(Color.primary, Color.primary.opacity(0.1))
            }
            .padding(.horizontal, 15)

            // Progress bar с drag gesture
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
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
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(audioService.durationFormatted)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            // Контролы: -15 / Play-Pause / +15
            HStack(spacing: 52) {
                Button {
                    audioService.seek(to: max(0, audioService.progress - 15 / max(audioService.duration, 1)))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary)
                }

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

                Button {
                    audioService.seek(to: min(1, audioService.progress + 15 / max(audioService.duration, 1)))
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, 8)

            // Скорость воспроизведения
            Button {
                audioService.cycleSpeed()
            } label: {
                Text(String(format: "%.2gx", audioService.playbackRate))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Constants.Colors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.accentLight)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Zoom transition modifier (iOS 18+)

private struct ZoomTransition: ViewModifier {
    let id: String
    let animation: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.navigationTransition(.zoom(sourceID: id, in: animation))
        } else {
            content
        }
    }
}
