//
//  MainTabView.swift
//  SenecaLetters
//

import SwiftUI

struct MainTabView: View {
    let apiClient: APIClient

    @State private var letterListVM: LetterListViewModel
    @State private var settingsVM: SettingsViewModel
    @State private var audioService = AudioService()
    @State private var expandMiniPlayer = false
    @Namespace private var animation
    @Environment(DownloadService.self) private var downloadService

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self._letterListVM = State(
            initialValue: LetterListViewModel(
                letterService: LetterServices(api: apiClient)
            )
        )
        self._settingsVM = State(
            initialValue: SettingsViewModel(apiClient: apiClient)
        )
    }

    var body: some View {
        TabView {
            Tab("Letters", systemImage: "doc.text") {
                LetterListView(viewModel: letterListVM)
            }

            Tab("Favorites", systemImage: "heart") {
                FavoritesView(letters: letterListVM.letters)
            }

            Tab("Quotes", systemImage: "text.quote") {
                QuotesView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView(viewModel: settingsVM)
            }

            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                LetterSearchView(viewModel: letterListVM)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            PlayerAreaView(
                audioService: audioService,
                onTap: { expandMiniPlayer = true }
            )
            .matchedTransitionSource(id: "MINIPLAYER", in: animation)
        }
        .tint(Constants.Colors.accent)
        .environment(audioService)
        .environment(downloadService)
        .fullScreenCover(isPresented: $expandMiniPlayer) {
            FullPlayerView(audioService: audioService)
                .navigationTransition(.zoom(sourceID: "MINIPLAYER", in: animation))
        }
    }
}
