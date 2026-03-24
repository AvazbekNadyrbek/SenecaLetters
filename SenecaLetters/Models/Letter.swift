//
//  Letter.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation

struct Letter: Codable, Identifiable, Hashable {
    
    let id: Int
    let number: Int
    let title: String
    let content: String?
    let summary: String?
    let audioUrl: String?
    let audioDuration: Int?
    let wordCount: Int?
    let themes: [Theme]?
    
}
