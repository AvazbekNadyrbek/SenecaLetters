//
//  LetterServices.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation


class LetterServices {
    
    
    private let api: APIClient
    
    init(api: APIClient) {
        self.api = api
    }
    
    func fetchLetters() async throws -> [Letter] {
        return try await api.get(path: "/letters?eagerload=true")
    }
    
    func fetchLetter(id: Int) async throws -> Letter {
        return try await api.get(path: "/letters/\(id)")
    }
    
    // MARK: - Добавить в избранное
    // Вызывает POST /api/favorites с телом запроса
    func addToFavorites(letterId: Int, userId: Int) async throws -> Favorite {
        let body = FavoriteRequest(
            createdAt: ISO8601DateFormatter().string(from: Date()),
            letter: LetterRef(id: letterId),
            user: UserRef(id: userId)
        )
        return try await api.request(
            path: "/favorites",
            method: "POST",
            body: body
        )
    }
    
    // MARK: - Удалить из избранного
     // Вызывает DELETE /api/favorites/5
     func removeFromFavorites(favoriteId: Int) async throws {
         let _: EmptyResponse = try await api.request(
             path: "/favorites/\(favoriteId)",
             method: "DELETE"
         )
     }
    
    
    // MARK: - Получить избранные письма юзера
    // Вызывает GET /api/favorites?userId.equals=1
    func fetchFavorites(userId: Int) async throws -> [Favorite] {
        return try await api.get(path: "/favorites?userId.equals=\(userId)")
    }
    
    // MARK: - Вспомогательные модели для запросов
    // Эти структуры нужны только для отправки данных на сервер

    struct Favorite: Codable, Identifiable {
        let id: Int
        let createdAt: String?
        let letter: Letter?
        let user: UserRef?
    }

    struct FavoriteRequest: Codable {
        let createdAt: String
        let letter: LetterRef
        let user: UserRef
    }

    // Когда добавляем в избранное — серверу достаточно знать только ID
    struct LetterRef: Codable {
        let id: Int
    }

    struct UserRef: Codable {
        let id: Int
    }

    // Для DELETE запросов которые не возвращают тело
    struct EmptyResponse: Codable {}
    
}
