//
//  ReadingProgress.swift
//  SenecaLetters
//

import Foundation
import SwiftData

@Model
class ReadingProgress {
    #Index<ReadingProgress>([\.letterId])

    @Attribute(.unique) var letterId: Int
    var page: Int
    var updatedAt: Date

    init(letterId: Int, page: Int) {
        self.letterId = letterId
        self.page = page
        self.updatedAt = Date()
    }
}
