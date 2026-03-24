# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a SwiftUI iOS app managed via Xcode. No SPM dependencies.

```bash
xcodebuild -project SenecaLetters.xcodeproj -scheme SenecaLetters -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Backend

Connects to `http://localhost:8080/api` (`Constants.baseURL`). JWT auth — login POSTs to `/authenticate` with `{username, password, rememberMe}`, receives `{"id_token": "..."}`. MVP hardcodes `admin`/`admin`; login failure is non-fatal.

## Architecture

MVVM with `@Observable` macro (iOS 17+) — no Combine, no `ObservableObject`.

**Data flow:**
```
APIClient → LetterServices → LetterListViewModel → LetterListView → ReaderView
                                                                         ↓
                                                                   AudioService (via @Environment)
```

- **`APIClient`** (`@Observable`): Generic `request<T: Decodable>()`. Stores JWT, attaches as `Bearer` header, clears on 401.
- **`LetterServices`**: Domain wrapper around `APIClient` — letters CRUD and favorites.
- **`LetterListViewModel`** (`@Observable @MainActor`): Holds `letters`, `isLoading`, `errorMessage`, `searchText`, `selectedTheme`. Derives `filteredLetters` and `allThemes`.
- **`AudioService`** (`@Observable @MainActor`): Wraps `AVPlayer`. Key state: `isPlaying`, `currentTime`, `duration`, `progress`, `playbackRate`, `currentLetterTitle`, `isPlayerActive`. `isPlayerActive` becomes `true` on the first `load()` call and is never reset — it gates the mini player visibility.
- **`ContentView`** / **`MainTabView`**: Entry point. Login happens in `.task`. `MainTabView` owns `LetterListViewModel`, `AudioService`, and `@Namespace animation` as `@State` — all survive tab switches. `AudioService` is injected into the environment via `.environment(audioService)`.

## Player UI Layer

The persistent bottom player spans two components:

- **`PlayerAreaView`** (`Componenets/`): Always visible — shows a placeholder ("Choose a letter to listen") when `audioService.isPlayerActive == false`, animates to `MiniPlayerView` when active. Receives `animation: Namespace.ID` for matched transition.
- **`MiniPlayerView`**: Compact player (album art, progress bar, play/pause, skip). Tapping opens `FullPlayerView` via `fullScreenCover`.
- **`FullPlayerView`**: Full-screen player with progress scrubber, transport controls, and speed cycling. Uses `ZoomTransition` (private `ViewModifier`) that applies `.navigationTransition(.zoom(...))` on iOS 18+ and is a no-op below.

**Platform branching in `MainTabView`:**
- iOS 26+: `tabViewBottomAccessory { PlayerAreaView(...) }` + `.tabBarMinimizeBehavior(.onScrollDown)`
- iOS < 26: `.overlay(alignment: .bottom)` with `PlayerAreaView` offset above the tab bar

## Key Conventions

- **`@Observable` + `@Bindable`**: ViewModels use `@Observable`. Views get two-way bindings via `@Bindable var viewModel`.
- **Dependency injection**: Each layer takes its dependency via `init` — `APIClient` → `LetterServices` → `ViewModel`.
- **Constants**: All app-wide values in `Constants` enum — `apiURL`, `baseURL`, `Colors.accent` (`#854F0B`), `Colors.accentLight` (`#FAEEDA`), `Fonts.serif(_:)` / `Fonts.serifBold(_:)` (Georgia).
- **Note**: The components folder is named `Componenets/` (typo in directory name) — match this when adding files there.

## Models

| Model | Key fields |
|-------|-----------|
| `Letter` | `id`, `number`, `title`, `content`, `summary`, `audioUrl`, `audioDuration`, `wordCount`, `themes` |
| `Theme` | `id`, `name`, `description`, `color` |
| `Highlight` | `selectedText`, `rangeStart`, `rangeEnd`, `color`, `note` |
| `LoginRequest` / `TokenResponse` | Auth DTOs |

## Planned Tabs

`MainTabView` has four tabs: **Letters** (implemented), **Favorites**, **Quotes**, **Settings** (all placeholder `Text` views).
