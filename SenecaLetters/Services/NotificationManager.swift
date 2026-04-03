//
//  NotificationManager.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/24/26.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    func scheduleDailyQuoteNotification(modelContext: ModelContext) {
        var fetchDescriptor = FetchDescriptor<SavedQuote>()
        fetchDescriptor.propertiesToFetch = [\.text]

        guard let quotes = try? modelContext.fetch(fetchDescriptor), !quotes.isEmpty else {
            print("No saved quotes available for scheduling a notification.")
            return
        }

        guard let randomQuote = quotes.randomElement() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your quote of the day"
        content.body = randomQuote.text
        content.sound = .default

        // Daily trigger at 09:00
        // var dateComponents = DateComponents()
        // dateComponents.hour = 9
        // dateComponents.minute = 0
        // let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)

        let request = UNNotificationRequest(
            identifier: "dailyQuoteNotification",
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
