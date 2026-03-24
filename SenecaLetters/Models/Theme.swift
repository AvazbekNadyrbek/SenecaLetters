//
//  Theme.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation

struct Theme: Codable, Identifiable, Hashable {
    
    let id: Int
    let name: String
    let description: String?
    let color: String?
    
}
