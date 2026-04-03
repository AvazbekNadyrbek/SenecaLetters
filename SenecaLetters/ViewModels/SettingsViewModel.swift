//
//  SettingsViewModel.swift
//  SenecaLetters
//

import Foundation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Confirmation Dialog State

    var showLogoutConfirmation = false
    var showClearProgressConfirmation = false
    var showClearFavoritesConfirmation = false
    var showClearQuotesConfirmation = false

    // MARK: - Dependencies

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Account

    func logout() {
        apiClient.logout()
    }

    // MARK: - Data Clearing

    func clearReadingProgress(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReadingProgress>()
        guard let items = try? modelContext.fetch(descriptor) else { return }
        items.forEach { modelContext.delete($0) }
    }

    func clearFavorites(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteLetter>()
        guard let items = try? modelContext.fetch(descriptor) else { return }
        items.forEach { modelContext.delete($0) }
    }

    func clearSavedQuotes(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SavedQuote>()
        guard let items = try? modelContext.fetch(descriptor) else { return }
        items.forEach { modelContext.delete($0) }
    }

    // MARK: - Notifications

    /// Handles toggling notifications on or off. Returns `false` if permission was denied.
    func handleNotificationToggle(enabled: Bool, modelContext: ModelContext) async -> Bool {
        if enabled {
            let granted = await requestNotificationPermission()
            if granted {
                NotificationManager.shared.scheduleDailyQuoteNotification(modelContext: modelContext)
            }
            return granted
        } else {
            NotificationManager.shared.cancelAllNotifications()
            return true
        }
    }

    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }
}
