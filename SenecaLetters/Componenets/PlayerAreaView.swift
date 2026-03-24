//
//  PlayerAreaView.swift
//  SenecaLetters
//

import SwiftUI

struct PlayerAreaView: View {
    var audioService: AudioService
    var onTap: () -> Void
    var animation: Namespace.ID

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
                .font(.system(size: 16))
                .foregroundStyle(Constants.Colors.accent.opacity(0.6))
            Text("Choose a letter to listen")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var miniPlayer: some View {
        if #available(iOS 18, *) {
            MiniPlayerView(audioService: audioService)
                .matchedTransitionSource(id: "MINIPLAYER", in: animation)
                .onTapGesture { onTap() }
        } else {
            MiniPlayerView(audioService: audioService)
                .onTapGesture { onTap() }
        }
    }
}
