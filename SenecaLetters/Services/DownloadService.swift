//
//  DownloadService.swift
//  SenecaLetters
//

import Foundation
import SwiftData

@MainActor
@Observable
class DownloadService {

    /// Cached set of letter IDs with a valid local file.
    /// This is a STORED property — @Observable tracks it, so views re-render
    /// the moment a download completes or a file is deleted.
    private(set) var downloadedLetterIds: Set<Int> = []

    /// Letters whose download task is currently running.
    var activeDownloads: Set<Int> = []

    /// Per-letter error from the most recent failed download attempt.
    var downloadErrors: [Int: String] = [:]

    private var downloadTasks: [Int: Task<Void, Never>] = [:]
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFromStore()
    }

    // MARK: - Queries

    func isDownloaded(letterId: Int) -> Bool {
        downloadedLetterIds.contains(letterId)
    }

    func isActive(letterId: Int) -> Bool {
        activeDownloads.contains(letterId)
    }

    /// Returns the on-disk URL only when the cached set says it's there
    /// AND the physical file actually exists.
    func localURL(for letterId: Int) -> URL? {
        guard downloadedLetterIds.contains(letterId),
              let record = fetchRecord(letterId: letterId)
        else { return nil }
        let url = record.localURL
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }

    // MARK: - Download

    /// Starts a managed, cancellable download task.
    /// Synchronous — no `Task {}` wrapper needed at the call site.
    /// Pass `authToken` if the audio endpoint requires a Bearer token.
    func startDownload(letterId: Int, audioURL: URL, authToken: String? = nil) {
        downloadTasks[letterId]?.cancel()
        downloadErrors[letterId] = nil

        downloadTasks[letterId] = Task {
            activeDownloads.insert(letterId)
            defer {
                activeDownloads.remove(letterId)
                downloadTasks[letterId] = nil
            }
            do {
                try await performDownload(letterId: letterId, audioURL: audioURL, authToken: authToken)
                // Update the cached set so every view observing it re-renders immediately.
                downloadedLetterIds.insert(letterId)
            } catch is CancellationError {
                // User cancelled or view disappeared — not an error worth showing.
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
        // Update cached set so views re-render immediately.
        downloadedLetterIds.remove(letterId)
    }

    func clearError(letterId: Int) {
        downloadErrors[letterId] = nil
    }

    // MARK: - Private

    /// Populates the in-memory cache from persisted SwiftData records on startup.
    private func loadFromStore() {
        let descriptor = FetchDescriptor<DownloadedAudio>()
        guard let records = try? modelContext.fetch(descriptor) else { return }
        downloadedLetterIds = Set(
            records
                .filter { FileManager.default.fileExists(atPath: $0.localURL.path()) }
                .map { $0.letterId }
        )
    }

    private func performDownload(letterId: Int, audioURL: URL, authToken: String? = nil) async throws {
        let audioDir = URL.documentsDirectory.appending(path: "audio", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)

        let relativePath = "audio/letter-\(letterId).mp3"
        let destinationURL = URL.documentsDirectory.appending(path: relativePath)

        // Build request — add Bearer token if the endpoint requires authentication.
        var request = URLRequest(url: audioURL)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // URLSession suspends here — MainActor is free during the transfer.
        let (tempURL, response) = try await URLSession.shared.download(for: request)

        // Reject server error responses (401, 404, 500…) before saving anything to disk.
        // Without this check a 401 HTML page would be saved as an "audio" file.
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }

        // Check cancellation after resuming — the task may have been cancelled
        // while URLSession was finishing the last bytes.
        try Task.checkCancellation()

        let fileSize = (response as? HTTPURLResponse)
            .flatMap { $0.expectedContentLength >= 0 ? Int64($0.expectedContentLength) : nil } ?? 0

        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        // Remove any stale record before inserting the fresh one.
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
