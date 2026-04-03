//
//  AuthModel.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation

struct LoginRequest: Codable{
    
    let username: String
    let password: String
    let rememberMe: Bool
    
}

struct TokenResponse: Codable{

    let idToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}

struct RegisterRequest: Codable {
    let login: String       // username
    let email: String
    let password: String
}

struct AppleAuthRequest: Encodable {
    let identityToken: String   // JWT от Apple
    let userIdentifier: String  // Stable per-app Apple User ID
    let email: String?          // Only present on first sign-in
    let fullName: String?       // Only present on first sign-in
}
