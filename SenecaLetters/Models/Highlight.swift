//
//  Highlight.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation

struct Highlight: Codable, Identifiable, Hashable {
    
    let id: Int
    let selectedText: String
    let rangeStart: Int
    let rangeEnd: Int
    let color: String
    let note: String?
    let createdAt: String?
    
    
}
