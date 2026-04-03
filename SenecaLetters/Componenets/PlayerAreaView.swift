//
//  PlayerAreaView.swift
//  SenecaLetters
//

import SwiftUI

struct PlayerAreaView: View {
    var audioService: AudioService
    var onTap: () -> Void

    var body: some View {
        Group {
            if audioService.isPlayerActive {
                miniPlayer
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                placeholder
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.4), value: audioService.isPlayerActive)
    }

    private var placeholder: some View {
        HStack(spacing: 10) {
            Image(systemName: "headphones")
                .font(.callout)
                .foregroundStyle(Constants.Colors.accent.opacity(0.6))
            Text("Choose a letter to listen")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }

    private var miniPlayer: some View {
        Button(action: onTap) {
            MiniPlayerView(audioService: audioService)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open audio player")
    }
}

//MiniPlayerView(audioService: audioService)
//     47 -            .background {
//     48 -                Button("Open audio player", action: onTap)
//     49 -                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//     50 -                    .buttonStyle(.plain)
//     51 -            }
