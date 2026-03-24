# SenecaLetters Project Overview

SenecaLetters is an iOS application built using SwiftUI, providing users with access to Seneca's letters. The app focuses on delivering a rich reading experience with features such as letter browsing, search, thematic filtering, and audio playback for letters. It also allows users to save favorite letters and quotes, manage user authentication, and customize their reading environment with various themes and font sizes. The application leverages modern Apple frameworks like SwiftUI and SwiftData, and is designed to adapt its UI for different iOS versions.

## Key Features

*   **Letter Browsing and Reading**: Access to a collection of Seneca's letters with customizable reading themes and font sizes.
*   **Search and Filtering**: Users can search for letters by title or content and filter them by themes.
*   **Audio Playback**: Listen to the audio versions of the letters.
*   **Favorites and Quotes**: Save favorite letters and significant quotes.
*   **User Authentication**: Secure login and registration functionality.
*   **Customizable Reader**: Multiple reading themes (light, sepia, dark) and adjustable font sizes.
*   **Notifications**: Local notifications for daily quotes.
*   **Dark/Light Mode**: Supports system-wide dark and light modes.
*   **Adaptive UI**: UI elements (like tab bars) adapt to different iOS versions (e.g., iOS 18+, iOS 26+).

## Technologies Used

*   **Frontend**: SwiftUI
*   **Data Persistence**: SwiftData (for `SavedQuote` and `FavoriteLetter`)
*   **Networking**: `URLSession` via `APIClient`
*   **Audio Playback**: `AVFoundation` via `AudioService`
*   **Localization**: Content hints at potential Russian localization (e.g., "Cенека", comments in Russian).

## Architecture

The project largely follows the MVVM (Model-View-ViewModel) architectural pattern.

*   **Models**: Define the data structures for the application, such as `Letter`, `Theme`, `SavedQuote`, `FavoriteLetter`, `Highlight`, and authentication-related models (`AuthModel.swift`).
*   **Views**: Represent the user interface components and interact with ViewModels to display data. Key views include `ContentView`, `LetterListView`, `ReaderView`, `AuthView`, `FavoritesView`, `QuotesView`, `FullPlayerView`, and various smaller reusable components.
*   **ViewModels**: Act as intermediaries between Views and Models, providing data and handling presentation logic for the Views. Examples include `LetterListViewModel` and `AuthViewModel`.
*   **Services**: Handle specific functionalities that are not directly tied to UI or data models.
    *   `APIClient`: Manages all API interactions, including authentication and data fetching.
    *   `AudioService`: Controls audio playback for letters.
    *   `LetterServices`: Provides an abstraction layer for fetching letters using the `APIClient`.
    *   `NotificationManager`: Manages local notifications.
*   **Utilities**: Contains helper classes and constants, such as `Constants` (defining URLs, colors, fonts, reader themes) and `TextPaginator` (for efficient text pagination in the reader).

## Building and Running

This is an Xcode project. To build and run the application:

1.  **Open in Xcode**: Navigate to the project directory and open `SenecaLetters.xcodeproj` in Xcode.
2.  **Select a Device/Simulator**: Choose your target iOS device or simulator.
3.  **Run**: Click the "Run" button (Cmd+R) in Xcode.

**Backend Requirement**: The application is configured to connect to a backend server at `http://localhost:8080` (as defined in `Constants.swift`). Ensure a compatible backend service is running locally for full functionality.

## Development Conventions

*   Utilizes SwiftUI's `@Observable` macro for reactive data flow in ViewModels and Services.
*   `@AppStorage` is used for persisting user preferences and application settings.
*   Custom error handling is implemented via the `APIError` enum.
*   UI adaptations are made for different iOS versions to leverage new APIs while maintaining compatibility.
*   Local notifications are managed through `UNUserNotificationCenter`.