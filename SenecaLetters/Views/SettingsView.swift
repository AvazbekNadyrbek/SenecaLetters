//
//  SettingsView.swift
//  SenecaLetters
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext

    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("readerTheme") private var readerTheme = Constants.ReaderTheme.light.rawValue
    @AppStorage("readerFontSize") private var fontSize: Double = 17
    @AppStorage("dailyNotificationsEnabled") private var notificationsEnabled = false

    var body: some View {
        NavigationStack {
            List {
                AppHeaderSection()
                AppearanceSection(isDarkMode: $isDarkMode, readerTheme: $readerTheme)
                ReadingSection(fontSize: $fontSize)
                AudioSection()
                NotificationsSection(isEnabled: $notificationsEnabled) { enabled in
                    let allowed = await viewModel.handleNotificationToggle(
                        enabled: enabled,
                        modelContext: modelContext
                    )
                    if !allowed { notificationsEnabled = false }
                }
                DataSection(
                    onClearProgress: { viewModel.showClearProgressConfirmation = true },
                    onClearFavorites: { viewModel.showClearFavoritesConfirmation = true },
                    onClearQuotes: { viewModel.showClearQuotesConfirmation = true }
                )
                AccountSection(onLogout: { viewModel.showLogoutConfirmation = true })
                AboutSection()
            }
            .navigationTitle("Settings")
        }
        .confirmationDialog(
            "Log Out",
            isPresented: $viewModel.showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) { viewModel.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be returned to the login screen.")
        }
        .confirmationDialog(
            "Clear Reading Progress",
            isPresented: $viewModel.showClearProgressConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Progress", role: .destructive) {
                viewModel.clearReadingProgress(modelContext: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your page positions for all letters will be reset.")
        }
        .confirmationDialog(
            "Clear Favorites",
            isPresented: $viewModel.showClearFavoritesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Favorites", role: .destructive) {
                viewModel.clearFavorites(modelContext: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All saved favorites will be removed.")
        }
        .confirmationDialog(
            "Clear Saved Quotes",
            isPresented: $viewModel.showClearQuotesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Quotes", role: .destructive) {
                viewModel.clearSavedQuotes(modelContext: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All your saved quotes will be permanently deleted.")
        }
    }
}

// MARK: - App Header

private struct AppHeaderSection: View {
    var body: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Constants.Colors.accent, in: .rect(cornerRadius: 14))
                    .shadow(color: Constants.Colors.accent.opacity(0.3), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Seneca Letters")
                        .font(Constants.Fonts.serifBold(18, relativeTo: .headline))
                    Text("126 letters of wisdom")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: - Appearance Section

private struct AppearanceSection: View {
    @Binding var isDarkMode: Bool
    @Binding var readerTheme: String

    var body: some View {
        Section("Appearance") {
            Toggle(isOn: $isDarkMode) {
                SettingsLabel(title: "Dark Mode", systemImage: "moon.fill", color: .purple)
            }

            Picker(selection: $readerTheme) {
                ForEach(Constants.ReaderTheme.allCases, id: \.rawValue) { theme in
                    Label(theme.rawValue.capitalized, systemImage: theme.iconName)
                        .tag(theme.rawValue)
                }
            } label: {
                SettingsLabel(title: "Reader Theme", systemImage: "paintpalette", color: .purple)
            }
        }
    }
}

// MARK: - Reading Section

private struct ReadingSection: View {
    @Binding var fontSize: Double

    var body: some View {
        Section {
            LabeledContent {
                Text(Int(fontSize), format: .number)
                    .foregroundStyle(.secondary)
            } label: {
                SettingsLabel(title: "Font Size", systemImage: "textformat.size", color: .orange)
            }

            Slider(value: $fontSize, in: 12...28, step: 1)
                .tint(Constants.Colors.accent)

            Text("The unexamined life is not worth living.")
                .font(Constants.Fonts.serif(fontSize))
                .foregroundStyle(Constants.ReaderTheme.sepia.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Constants.ReaderTheme.sepia.background,
                            in: .rect(cornerRadius: 10))
                .animation(.easeInOut(duration: 0.15), value: fontSize)
        } header: {
            Text("Reading")
        }
    }
}

// MARK: - Audio Section

private struct AudioSection: View {
    @Environment(AudioService.self) private var audioService

    private let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        @Bindable var audioService = audioService

        Section("Audio") {
            Picker(selection: $audioService.playbackRate) {
                ForEach(speeds, id: \.self) { speed in
                    Text(Double(speed), format: .number.precision(.fractionLength(0...2)))
                        .tag(speed)
                }
            } label: {
                SettingsLabel(title: "Playback Speed", systemImage: "speedometer", color: .blue)
            }
        }
    }
}

// MARK: - Notifications Section

private struct NotificationsSection: View {
    @Binding var isEnabled: Bool
    let onToggle: (Bool) async -> Void

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                SettingsLabel(title: "Daily Quote", systemImage: "bell.fill", color: .red)
            }
            .onChange(of: isEnabled) { _, newValue in
                Task { await onToggle(newValue) }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Receive a daily reminder with one of your saved quotes.")
        }
    }
}

// MARK: - Data Section

private struct DataSection: View {
    let onClearProgress: () -> Void
    let onClearFavorites: () -> Void
    let onClearQuotes: () -> Void

    var body: some View {
        Section {
            Button(role: .destructive, action: onClearProgress) {
                SettingsLabel(title: "Clear Reading Progress",
                              systemImage: "arrow.counterclockwise",
                              color: .gray)
            }
            Button(role: .destructive, action: onClearFavorites) {
                SettingsLabel(title: "Clear Favorites",
                              systemImage: "heart.slash",
                              color: .gray)
            }
            Button(role: .destructive, action: onClearQuotes) {
                SettingsLabel(title: "Clear Saved Quotes",
                              systemImage: "text.badge.minus",
                              color: .gray)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("These actions cannot be undone.")
        }
    }
}

// MARK: - Account Section

private struct AccountSection: View {
    let onLogout: () -> Void

    var body: some View {
        Section("Account") {
            Button(role: .destructive, action: onLogout) {
                SettingsLabel(
                    title: "Log Out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    color: Constants.Colors.accent
                )
            }
        }
    }
}

// MARK: - About Section

private struct AboutSection: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        Section("About") {
            LabeledContent {
                Text(appVersion)
                    .foregroundStyle(.secondary)
            } label: {
                SettingsLabel(title: "Version", systemImage: "info.circle.fill", color: .gray)
            }
        }
    }
}

// MARK: - Settings Label

private struct SettingsLabel: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: .rect(cornerRadius: 6))
        }
    }
}
