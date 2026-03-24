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
