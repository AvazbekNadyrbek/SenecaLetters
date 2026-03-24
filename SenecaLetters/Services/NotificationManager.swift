//
//  NotificationManager.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/24/26.
//

import Foundation
import SwiftData
import UserNotifications
import SwiftUI


class NotificationManager {
    
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheladuleDailyQuoteNotification(modelContext: ModelContext) {
        
        
        // 1. Taking all quotes from SwiftData
        
        let fetchDescriptor = FetchDescriptor<SavedQuote>()
        
        guard let quotes = try? modelContext.fetch(fetchDescriptor), !quotes.isEmpty else {
            print("Нет сохраненных цитат для планирования уведомления.")
            return
        }
        
        // 2. Choosing a random Quote
        guard let randomQuote = quotes.randomElement() else { return }
        
        // 3.Creating a content for notification
        
        let content = UNMutableNotificationContent()
        content.title = "Ваши цитата дня"
        content.body = randomQuote.text
        content.sound = UNNotificationSound.default
        
        // 4. Creating a trigger (ata 9:00 pm daily)
        
//        var dateComponents = DateComponents()
//        dateComponents.hour = 9
//        dateComponents.minute = 0
//        
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
        
        // 5. Creating and register a request
        
        let request = UNNotificationRequest(identifier: "dailyQuoteNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка планирования уведомления: \(error.localizedDescription)")
            } else {
                print("Ежедневное уведомление с цитатой успешно запланировано!")
            }
        }
    }
    
    // Функция для отмены всех запланированных уведомлений (может пригодиться)
        func cancelAllNotifications() {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("Все запланированные уведомления отменены.")
        }
    
}
