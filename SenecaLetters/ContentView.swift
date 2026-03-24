//
//  ContentView.swift
//  SenecaLetters
//

import SwiftUI

struct ContentView: View {
    // apiClient is the single source of truth for auth state.
    // It lives here so it outlives both AuthView and MainTabView.
    @State private var apiClient = APIClient()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        // apiClient.isAuthenticated is a computed property (token != nil).
        // Because APIClient is @Observable, SwiftUI watches it automatically —
        // no need for .onChange or manual state syncing.
        Group {
            if apiClient.isAuthenticated {
                MainTabView(apiClient: apiClient)
            } else {
                AuthView(viewModel: AuthViewModel(apiClient: apiClient))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    let apiClient: APIClient

    @State private var letterListVM: LetterListViewModel
    @State private var audioService = AudioService()
    @State private var expandMiniPlayer = false
    @Namespace private var animation

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self._letterListVM = State(
            initialValue: LetterListViewModel(
                letterService: LetterServices(api: apiClient)
            )
        )
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                tabView_iOS26
            } else if #available(iOS 18, *) {
                tabView_iOS18
            } else {
                tabView_legacy
            }
        }
        .tint(Constants.Colors.accent)
        .environment(audioService)
        .fullScreenCover(isPresented: $expandMiniPlayer) {
            FullPlayerView(audioService: audioService, animation: animation)
        }
    }

    // MARK: - iOS 26+

    @available(iOS 26, *)
    private var tabView_iOS26: some View {
        tabsWithSearchRole
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                PlayerAreaView(audioService: audioService, onTap: { expandMiniPlayer = true }, animation: animation)
            }
    }

    // MARK: - iOS 18–25

    @available(iOS 18, *)
    private var tabView_iOS18: some View {
        tabsWithSearchRole
            .overlay(alignment: .bottom) {
                PlayerAreaView(audioService: audioService, onTap: { expandMiniPlayer = true }, animation: animation)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 15, style: .continuous))
                    .padding(.horizontal, 15)
                    .offset(y: -49)
            }
            .ignoresSafeArea(.keyboard, edges: .all)
    }

    // MARK: - Shared Tab structure for iOS 18+ (Tab API + Search role)

    @available(iOS 18, *)
    @ViewBuilder
    private var tabsWithSearchRole: some View {
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
                Text("Settings")
            }

            // Search tab — нативная iOS 18+ роль, иконка внизу таббара
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                NavigationStack {
                    List {
                        ForEach(letterListVM.filteredLetters) { letter in
                            NavigationLink(value: letter) {
                                LetterRow(letter: letter)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Search")
                    .searchable(
                        text: $letterListVM.searchText,
                        prompt: "Search letters"
                    )
                    .navigationDestination(for: Letter.self) { letter in
                        ReaderView(letter: letter)
                    }
                    .overlay {
                        if !letterListVM.searchText.isEmpty && letterListVM.filteredLetters.isEmpty {
                            ContentUnavailableView.search(text: letterListVM.searchText)
                        }
                    }
                    .task {
                        if letterListVM.letters.isEmpty {
                            await letterListVM.loadLetters()
                        }
                    }
                }
            }
        }
    }

    // MARK: - iOS < 18 legacy (старый .tabItem API)

    private var tabView_legacy: some View {
        TabView {
            LetterListView(viewModel: letterListVM)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Letters")
                }

            FavoritesView(letters: letterListVM.letters)
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }

            QuotesView()
                .tabItem {
                    Image(systemName: "text.quote")
                    Text("Quotes")
                }

            Text("Settings")
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .overlay(alignment: .bottom) {
            PlayerAreaView(audioService: audioService, onTap: { expandMiniPlayer = true }, animation: animation)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 15, style: .continuous))
                .padding(.horizontal, 15)
                .offset(y: -49)
        }
        .ignoresSafeArea(.keyboard, edges: .all)
    }
}

#Preview {
    ContentView()
}
