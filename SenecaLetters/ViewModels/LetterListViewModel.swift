//
//  LetterListViewModel.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation

@MainActor
@Observable
class LetterListViewModel {
    
    // MARK: - Данные для View
      
    // Список писем — View покажет их в списке
    var letters: [Letter] = []
    
    // Загружаемся ли мы сейчас? View покажет spinner
    var isLoading: Bool = false
    
    // Текст ошибки — View покажет alert
    var errorMessage: String? = nil
    
    // Текст поиска — View привяжет к SearchBar
    var searchText = ""
    
    // Выбранная тема для фильтрации
    var selectedTheme: String? = nil
    
    // MARK: - Зависимости
     
    // LetterService делает реальную работу с API
    private let letterService: LetterServices
    
    init(letterService: LetterServices) {
        self.letterService = letterService
    }
    
    // MARK: - Отфильтрованные письма
       // Это вычисляемое свойство — пересчитывается автоматически
       // когда меняется searchText, selectedTheme или letters
       var filteredLetters: [Letter] {
           var result = letters
           
           // Фильтр по поиску
           if !searchText.isEmpty {
               result = result.filter { letter in
                   letter.title.localizedStandardContains(searchText) ||
                   (letter.content?.localizedStandardContains(searchText) ?? false)
               }
           }
           
           // Фильтр по теме
           if let theme = selectedTheme {
               result = result.filter { letter in
                   letter.themes?.contains(where: { $0.name == theme }) ?? false
               }
           }
           
           return result
       }
    
    // MARK: - Все уникальные темы для фильтра
       var allThemes: [String] {
           let themes = letters.flatMap { $0.themes ?? [] }
           let names = Set(themes.map { $0.name })
           return Array(names).sorted()
       }
       
       // MARK: - Загрузить письма с сервера
       func loadLetters() async {
           // 1. Показываем spinner
           isLoading = true
           errorMessage = nil
           
           do {
               // 2. Просим LetterService загрузить письма
               letters = try await letterService.fetchLetters()
               
               print("✅ Loaded \(letters.count) letters")  // ← добавь это
           } catch {
               // 3. Если ошибка — показываем сообщение
               errorMessage = error.localizedDescription
               print("❌ Error loading letters: \(error)")  // ← и это

           }
           
           // 4. Убираем spinner
           isLoading = false
       }
       
       // MARK: - Выбрать/снять фильтр по теме
       func toggleTheme(_ theme: String) {
           if selectedTheme == theme {
               selectedTheme = nil  // Снять фильтр
           } else {
               selectedTheme = theme  // Применить фильтр
           }
       }
}
