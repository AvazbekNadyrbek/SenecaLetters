//
//  DownloadService.swift
//  SenecaLetters
//

import Foundation
import SwiftData

@MainActor
@Observable
class DownloadService {

    /// Letters currently being downloaded.
    var activeDownloads: Set<Int> = []

    /// Per-letter error message, set when a download fails.
    var downloadErrors: [Int: String] = [:]

    private var downloadTasks: [Int: Task<Void, Never>] = [:]
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Queries

    func isDownloaded(letterId: Int) -> Bool {
        localURL(for: letterId) != nil
    }

    /// Returns the on-disk URL only when both the SwiftData record and the
    /// physical file exist. Guards against stale records after manual deletion.
    func localURL(for letterId: Int) -> URL? {
        guard let record = fetchRecord(letterId: letterId) else { return nil }
        let url = record.localURL
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }

    func isActive(letterId: Int) -> Bool {
        activeDownloads.contains(letterId)
    }

    // MARK: - Download

    /// Starts a managed download task. Synchronous — no `Task {}` needed in the view.
    func startDownload(letterId: Int, audioURL: URL) {
        // Cancel any in-flight download for this letter before starting a new one.
        downloadTasks[letterId]?.cancel()
        downloadErrors[letterId] = nil

        downloadTasks[letterId] = Task {
            activeDownloads.insert(letterId)
            defer {
                activeDownloads.remove(letterId)
                downloadTasks[letterId] = nil
            }
            do {
                try await performDownload(letterId: letterId, audioURL: audioURL)
            } catch is CancellationError {
                // Normal: task was cancelled (view disappeared or user tapped cancel).
                // Do not surface this as an error.
            } catch {
                downloadErrors[letterId] = error.localizedDescription
            }
        }
    }

    func cancelDownload(letterId: Int) {
        downloadTasks[letterId]?.cancel()
    }

    // MARK: - Delete

    func delete(letterId: Int) throws {
        guard let record = fetchRecord(letterId: letterId) else { return }
        try? FileManager.default.removeItem(at: record.localURL)
        modelContext.delete(record)
        try modelContext.save()
    }

    func clearError(letterId: Int) {
        downloadErrors[letterId] = nil
    }

    // MARK: - Private

    private func performDownload(letterId: Int, audioURL: URL) async throws {
        let audioDir = URL.documentsDirectory.appending(path: "audio", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)

        let relativePath = "audio/letter-\(letterId).mp3"
        let destinationURL = URL.documentsDirectory.appending(path: relativePath)

        // URLSession.download suspends here — MainActor is free during the transfer.
        let (tempURL, response) = try await URLSession.shared.download(from: audioURL)

        // Cancellation check after resuming — in case the task was cancelled
        // while URLSession was finishing the last bytes.
        try Task.checkCancellation()

        let fileSize = (response as? HTTPURLResponse)
            .flatMap { $0.expectedContentLength >= 0 ? Int64($0.expectedContentLength) : nil } ?? 0

        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        if let existing = fetchRecord(letterId: letterId) {
            modelContext.delete(existing)
        }
        modelContext.insert(DownloadedAudio(
            letterId: letterId,
            localPath: relativePath,
            fileSizeBytes: fileSize
        ))
        try modelContext.save()
    }

    private func fetchRecord(letterId: Int) -> DownloadedAudio? {
        var descriptor = FetchDescriptor<DownloadedAudio>(
            predicate: #Predicate { $0.letterId == letterId }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
