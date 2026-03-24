//
//  FavoriteLetter.swift
//  SenecaLetters
//

import Foundation
import SwiftData

@Model
class FavoriteLetter {
    var letterId: Int
    var savedAt: Date

    init(letterId: Int) {
        self.letterId = letterId
        self.savedAt = Date()
    }
}
