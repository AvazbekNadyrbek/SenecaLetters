//
//  ReaderView.swift
//  SenecaLetters
//

import SwiftUI
import SwiftData

// MARK: - Paged reader
// Horizontal swipe-to-turn-page layout. Text is paginated via TextPaginator
// (TextKit 1) so each page fits exactly within the screen without scrolling.

struct ReaderView: View {
    let letter: Letter
    @Environment(AudioService.self) private var audioService
    @Environment(DownloadService.self) private var downloadService
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteLetter]
    @Query private var allSavedQuotes: [SavedQuote]
    @Query private var allProgress: [ReadingProgress]

    init(letter: Letter) {
        self.letter = letter
        let letterId = letter.id
        let letterNumber = letter.number
        _favorites = Query(filter: #Predicate<FavoriteLetter> { $0.letterId == letterId })
        _allSavedQuotes = Query(filter: #Predicate<SavedQuote> { $0.letterNumber == letterNumber })
        _allProgress = Query(filter: #Predicate<ReadingProgress> { $0.letterId == letterId })
    }

    // Persisted reading preferences (readerTheme and isDarkMode stay in sync)
    @AppStorage("readerFontSize") private var fontSize: Double = 17
    @AppStorage("readerTheme")    private var rawTheme: String = Constants.ReaderTheme.light.rawValue
    @AppStorage("isDarkMode")     private var isDarkMode: Bool = false

    @State private var currentPage: Int? = 0
    @State private var pages: [String] = []
    @State private var showQuoteSaved = false
    @State private var showDownloaded = false
    @State private var feedbackTrigger = false

    private var theme: Constants.ReaderTheme {
        Constants.ReaderTheme(rawValue: rawTheme) ?? .light
    }

    private var savedPage: Int {
        allProgress.first(where: { $0.letterId == letter.id })?.page ?? 0
    }

    private var savedQuoteTexts: [String] {
        allSavedQuotes
            .filter { $0.letterNumber == letter.number }
            .map { $0.text }
    }

    private var isFavorite: Bool {
        favorites.contains { $0.letterId == letter.id }
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.letterId == letter.id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteLetter(letterId: letter.id))
        }
        try? modelContext.save()
    }

    private var isCurrentLetter: Bool {
        audioService.currentLetterTitle == "Letter \(letter.number)"
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            // UITextView has textContainerInset: top 0, left 24, right 24, bottom 24.
            // Subtract those from the page dimensions so the paginator knows the exact
            // text area available inside each UITextView frame.
            let textPageSize = CGSize(
                width:  geo.size.width - 48,        // 24 left + 24 right
                height: geo.size.height - 2 - 24    // 2 progress bar + 24 bottom inset
            )

            ZStack(alignment: .top) {
                theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ReaderProgressBar(
                        pageCount: pages.count,
                        currentPage: currentPage ?? 0,
                        totalWidth: geo.size.width,
                        theme: theme
                    )

                    if pages.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0) {
                                ForEach(pages.indices, id: \.self) { idx in
                                    SelectableLetterText(
                                        content: pages[idx],
                                        savedQuoteTexts: savedQuoteTexts,
                                        fontSize: CGFloat(fontSize),
                                        theme: theme,
                                        onSaveQuote: saveQuote
                                    )
                                    // Frame fills the full page; UITextView handles its own insets.
                                    .frame(width: geo.size.width,
                                           height: geo.size.height,
                                           alignment: .topLeading)
                                    .id(idx)
                                    .padding(.top, 20)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $currentPage)
                        .onChange(of: currentPage) { _, newPage in
                            guard let newPage else { return }
                            saveProgress(newPage)
                        }
                    }
                }
            }
            // Re-paginate whenever font size or screen dimensions change.
            .task(id: "\(Int(fontSize))-\(Int(geo.size.width))-\(Int(geo.size.height))") {
                repaginate(textPageSize: textPageSize)
            }
        }
        .background(theme.background)
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                if showDownloaded {
                    DownloadedBanner()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if showQuoteSaved {
                    QuoteSavedBanner()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: downloadService.activeDownloads) { oldValue, newValue in
            let wasActive = oldValue.contains(letter.id)
            let isNowActive = newValue.contains(letter.id)
            // Transition from active → idle means download just finished
            if wasActive && !isNowActive && downloadService.isDownloaded(letterId: letter.id) {
                withAnimation(.spring(duration: 0.3)) { showDownloaded = true }
                Task {
                    try? await Task.sleep(for: .seconds(2.5))
                    withAnimation(.easeOut(duration: 0.3)) { showDownloaded = false }
                }
            }
        }
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        .navigationTitle(letter.title)
        .navigationSubtitle(Text("Письмо \(letter.number)"))
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
        .toolbar { toolbarContent }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: toggleFavorite) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
            }
            .foregroundStyle(isFavorite ? .red : .secondary)


            // Font size + theme in one compact menu
            Menu {
                Section("Font Size") {
                    Button {
                        fontSize = min(28, fontSize + 2)
                    } label: {
                        Label("Larger", systemImage: "textformat.size.larger")
                    }
                    Button {
                        fontSize = max(12, fontSize - 2)
                    } label: {
                        Label("Smaller", systemImage: "textformat.size.smaller")
                    }
                }
                Section("Theme") {
                    ForEach(Constants.ReaderTheme.allCases, id: \.rawValue) { t in
                        Button {
                            rawTheme = t.rawValue
                            // Keep isDarkMode in sync so the toolbar in LetterListView
                            // and app-wide color scheme always agree.
                            isDarkMode = (t == .dark)
                        } label: {
                            Label(
                                t.rawValue.capitalized,
                                systemImage: t.rawValue == rawTheme ? "checkmark" : t.iconName
                            )
                        }
                    }
                }
            } label: {
                Label("Reading Settings", systemImage: "textformat")
                    .labelStyle(.iconOnly)
            }
        }

        if letter.audioUrl != nil {
            ToolbarItemGroup(placement: .confirmationAction) {
                ReaderAudioButton(
                    letter: letter,
                    audioService: audioService,
                    downloadService: downloadService,
                    isCurrentLetter: isCurrentLetter
                )
            }
        }
    }

    // MARK: - Pagination

    private func repaginate(textPageSize: CGSize) {
        let text = letter.content ?? ""
        guard !text.isEmpty, textPageSize.width > 0, textPageSize.height > 0 else {
            pages = text.isEmpty ? [] : [text]
            currentPage = 0
            return
        }
        let attributed = TextPaginator.buildAttributedString(
            text: text,
            fontSize: CGFloat(fontSize),
            theme: theme
        )
        pages = TextPaginator.paginate(attributedText: attributed, pageSize: textPageSize)
        currentPage = min(savedPage, max(0, pages.count - 1))
    }

    // MARK: - Save quote

    private func saveQuote(_ text: String) {
        guard !text.isEmpty else { return }

        let quote = SavedQuote(
            text: text,
            letterTitle: letter.title,
            letterNumber: letter.number
        )
        modelContext.insert(quote)
        try? modelContext.save()
        feedbackTrigger.toggle()
        withAnimation(.spring(duration: 0.3)) { showQuoteSaved = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) { showQuoteSaved = false }
        }

        NotificationManager.shared.scheduleDailyQuoteNotification(modelContext: modelContext)
    }

    // MARK: - Save reading progress

    private func saveProgress(_ page: Int) {
        if let existing = allProgress.first(where: { $0.letterId == letter.id }) {
            existing.page = page
            existing.updatedAt = Date()
        } else {
            modelContext.insert(ReadingProgress(letterId: letter.id, page: page))
        }
        try? modelContext.save()
    }
}

// MARK: - Reader Progress Bar

private struct ReaderProgressBar: View {
    let pageCount: Int
    let currentPage: Int
    let totalWidth: CGFloat
    let theme: Constants.ReaderTheme

    var body: some View {
        let total = max(1, pageCount)
        let progress = CGFloat(currentPage + 1) / CGFloat(total)
        ZStack(alignment: .leading) {
            Rectangle().fill(theme.foreground.opacity(0.12))
            Rectangle()
                .fill(Constants.Colors.accent)
                .frame(width: totalWidth * progress)
                .animation(.easeInOut(duration: 0.15), value: currentPage)
        }
        .frame(height: 2)
    }
}

// MARK: - Reader Audio Button

private struct ReaderAudioButton: View {
    let letter: Letter
    let audioService: AudioService
    let downloadService: DownloadService
    let isCurrentLetter: Bool

    var body: some View {
        HStack(spacing: 7) {
            // Simple SF symbol play/pause button
            Button {
                if isCurrentLetter {
                    audioService.togglePlayPause()
                } else if let audioUrl = letter.audioUrl {
                    audioService.load(
                        urlString: audioUrl,
                        localURL: downloadService.localURL(for: letter.id),
                        title: "Letter \(letter.number)",
                        subtitle: letter.title
                    )
                    audioService.togglePlayPause()
                }
            } label: {
                Image(systemName: isCurrentLetter && audioService.isPlaying
                      ? "pause.circle.fill"
                      : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Constants.Colors.accent)
            }
            .accessibilityLabel(isCurrentLetter && audioService.isPlaying ? "Pause" : "Play")

            DownloadButton(letter: letter, downloadService: downloadService)
        }
    }
}

// MARK: - Download Button

private struct DownloadButton: View {
    let letter: Letter
    let downloadService: DownloadService

    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if downloadService.isActive(letterId: letter.id) {
                // Indeterminate spinner — we don't have byte-level progress from URLSession
                ProgressView()
                    .tint(Constants.Colors.accent)
                    .accessibilityLabel("Downloading…")
            } else if let errorMessage = downloadService.downloadErrors[letter.id] {
                // Download failed — show error icon, tap to dismiss
                Button("Download error: \(errorMessage)", systemImage: "exclamationmark.circle.fill") {
                    downloadService.clearError(letterId: letter.id)
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.red)
            } else if downloadService.isDownloaded(letterId: letter.id) {
                // Downloaded — tap to confirm deletion
                Button("Remove offline audio", systemImage: "arrow.down.circle.fill") {
                    showDeleteConfirmation = true
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(Constants.Colors.accent)
                .confirmationDialog(
                    "Remove offline audio?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Remove Download", role: .destructive) {
                        try? downloadService.delete(letterId: letter.id)
                    }
                } message: {
                    Text("You can download it again any time while connected.")
                }
            } else {
                // Not downloaded — tap to download
                Button("Download for offline", systemImage: "arrow.down.circle") {
                    guard let audioUrlString = letter.audioUrl,
                          let audioURL = URL(string:
                            audioUrlString.hasPrefix("http")
                                ? audioUrlString
                                : Constants.baseURL + audioUrlString)
                    else { return }
                    // startDownload is synchronous — no Task{} needed in the view
                    downloadService.startDownload(letterId: letter.id, audioURL: audioURL)
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Quote Saved Banner

private struct QuoteSavedBanner: View {
    var body: some View {
        Label("Quote saved", systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Constants.Colors.accent, in: .capsule)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.bottom, 24)
    }
}

// MARK: - Downloaded Banner

private struct DownloadedBanner: View {
    var body: some View {
        Label("Saved for offline listening", systemImage: "arrow.down.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Constants.Colors.accent, in: .capsule)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.bottom, 24)
    }
}
