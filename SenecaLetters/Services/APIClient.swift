//
//  APIClient.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation

enum APIError: LocalizedError {
    
    case invalidURL // Incorrect URL
    case noData // Server answered with noData
    case unauthorized // No access to server/ token is exipred
    case serverError(Int) // Server has return a Error (404, 500 ..)
    case decodingError  // Json error
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data from server"
        case .unauthorized: return "Unauthorized / Please log in again"
        case .serverError(let code): return "Server error with code: \(code)"
        case .decodingError: return "Decoding error"
        }
    }
    
}

// MARK: API CLient = our Kellner
// @oberbale - seeing the changles automatically
@Observable
class APIClient {
    
    
    // Token of automatization - like ticken in closed Club
    // Withput this server cant send the data
    var token: String? = nil
    
    // Checking that login or not
    var isAuthenticated: Bool {
        return token != nil
    }
    
    func login(username: String, password: String) async throws -> Void {
        
        let loginRequest = LoginRequest(
            username: username,
            password: password,
            rememberMe: false
        )
        
        // 2. Отправляем POST запрос на /api/authenticate
        let response: TokenResponse = try await request(
            path: "/authenticate",
            method: "POST",
            body: loginRequest
        )
        
        
        
        // 3. Save the token that we are logged
        self.token = response.idToken
    }
    
    func register(username: String, email: String, password: String) async throws {
        let body = RegisterRequest(login: username, email: email, password: password)
        try await send(path: "/register", method: "POST", body: body)
    }

    // For endpoints that return no body (e.g. 201 Created with empty response)
    func send(path: String, method: String, body: (any Encodable)? = nil) async throws {
        guard let url = URL(string: Constants.apiURL + path) else { throw APIError.invalidURL }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { urlRequest.httpBody = try JSONEncoder().encode(body) }
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }
        if http.statusCode == 401 { self.token = nil; throw APIError.unauthorized }
        if http.statusCode >= 400 { throw APIError.serverError(http.statusCode) }
    }

    func logout() {
        token = nil
    }
    
    // This is a Heard of APICLient
    func request<T: Decodable>(
           path: String,
           method: String = "GET",
           body: (any Encodable)? = nil
       ) async throws -> T {
           
           // 1. Собираем URL
           // Например: http://localhost:8080/api/letters
           guard let url = URL(string: Constants.apiURL + path) else {
               throw APIError.invalidURL
           }
           
           // 2. Создаём запрос
           var urlRequest = URLRequest(url: url)
           urlRequest.httpMethod = method
           urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           // 3. Если есть токен — добавляем его в заголовок
           // Как показать пропуск охраннику
           if let token = token {
               urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           }
           
           // 4. Если есть тело запроса (POST/PUT) — кодируем в JSON
           if let body = body {
               urlRequest.httpBody = try JSONEncoder().encode(body)
           }
           
           // 5. Отправляем запрос и ждём ответ
           // async/await — Swift сам управляет ожиданием
           let (data, response) = try await URLSession.shared.data(for: urlRequest)
           
           // 6. Проверяем HTTP код ответа
           guard let httpResponse = response as? HTTPURLResponse else {
               throw APIError.noData
           }
           
           // 401 = "кто ты такой?" — токен истёк
           if httpResponse.statusCode == 401 {
               self.token = nil
               throw APIError.unauthorized
           }
           
           // Любой код >= 400 — это ошибка
           if httpResponse.statusCode >= 400 {
               throw APIError.serverError(httpResponse.statusCode)
           }
           
           // 7. Декодируем JSON в нашу модель (Letter, Theme, и т.д.)
           do {
               let decoder = JSONDecoder()
               return try decoder.decode(T.self, from: data)
           } catch {
               print("Decoding error: \(error)")
               throw APIError.decodingError
           }
       }
       
       // MARK: - GET запрос без тела (самый частый)
       // Упрощённая версия для простых GET запросов
       func get<T: Decodable>(path: String) async throws -> T {
           return try await request(path: path, method: "GET")
       }
   }
