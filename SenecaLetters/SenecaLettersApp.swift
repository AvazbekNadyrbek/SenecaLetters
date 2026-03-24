//
//  SenecaLettersApp.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import SwiftUI
import SwiftData

@main
struct SenecaLettersApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: setupNotifications)
        }
        .modelContainer(for: [SavedQuote.self, FavoriteLetter.self, ReadingProgress.self])
    }
    
    private func setupNotifications() {
            // Запрашиваем разрешение
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("Разрешение на уведомления получено.")
                } else if let error = error {
                    print("Ошибка при запросе разрешений: \(error.localizedDescription)")
                }
            }
        }
    
}
