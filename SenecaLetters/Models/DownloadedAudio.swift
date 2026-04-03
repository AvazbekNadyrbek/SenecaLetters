//
//  DownloadedAudio.swift
//  SenecaLetters
//

import Foundation
import SwiftData

@Model
class DownloadedAudio {
    #Index<DownloadedAudio>([\.letterId])

    var letterId: Int
    /// Relative path inside Documents — absolute path changes between app launches on iOS.
    var localPath: String
    var downloadedAt: Date
    var fileSizeBytes: Int64

    init(letterId: Int, localPath: String, fileSizeBytes: Int64) {
        self.letterId = letterId
        self.localPath = localPath
        self.downloadedAt = Date()
        self.fileSizeBytes = fileSizeBytes
    }

    /// Resolves the stored relative path to an absolute URL at runtime.
    var localURL: URL {
        URL.documentsDirectory.appending(path: localPath)
    }
}
