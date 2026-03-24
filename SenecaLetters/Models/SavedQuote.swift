//
//  SavedQuote.swift
//  SenecaLetters
//

import Foundation
import SwiftData

@Model
class SavedQuote {
    @Attribute(.unique) var id: UUID
    var text: String
    var letterTitle: String
    var letterNumber: Int
    var savedAt: Date

    init(text: String, letterTitle: String, letterNumber: Int) {
        self.id = UUID()
        self.text = text
        self.letterTitle = letterTitle
        self.letterNumber = letterNumber
        self.savedAt = Date()
    }
}
