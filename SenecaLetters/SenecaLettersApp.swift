//
//  SenecaLettersApp.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct SenecaLettersApp: App {

    private let container: ModelContainer
    @State private var downloadService: DownloadService

    init() {
        let schema = Schema([
            SavedQuote.self,
            FavoriteLetter.self,
            ReadingProgress.self,
            DownloadedAudio.self
        ])
        let container = try! ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self)
        self.container = container
        self._downloadService = State(
            initialValue: DownloadService(modelContext: container.mainContext)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await requestNotificationAuthorization() }
                .environment(downloadService)
        }
        .modelContainer(container)
    }

    private func requestNotificationAuthorization() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
        }
    }
}
