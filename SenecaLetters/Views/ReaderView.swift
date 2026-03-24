//
//  ReaderView.swift
//  SenecaLetters
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Paged reader
// Horizontal swipe-to-turn-page layout. Text is paginated via TextPaginator
// (TextKit 1) so each page fits exactly within the screen without scrolling.

struct ReaderView: View {
    let letter: Letter
    @Environment(AudioService.self) private var audioService
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteLetter]
    @Query private var allSavedQuotes: [SavedQuote]
    @Query private var allProgress: [ReadingProgress]
    
    // Persisted reading preferences (readerTheme and isDarkMode stay in sync)
    @AppStorage("readerFontSize") private var fontSize: Double = 17
    @AppStorage("readerTheme")    private var rawTheme: String = Constants.ReaderTheme.light.rawValue
    @AppStorage("isDarkMode")     private var isDarkMode: Bool = false
    
    
    @State private var currentPage: Int? = 0
    @State private var pages: [String] = []
    @State private var showQuoteSaved = false
    
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
                    progressBar(totalWidth: geo.size.width)
                    
                    if pages.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
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
            if showQuoteSaved { quoteSavedBanner }
        }
        .navigationTitle(letter.title)
        .navigationSubtitle(Text("Письмо \(letter.number)"))
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(isDarkMode ? .dark : .light, for: .navigationBar)
        .toolbar { toolbarContent }
    }
    
    // MARK: - Progress bar
    
    private func progressBar(totalWidth: CGFloat) -> some View {
        let total    = max(1, pages.count)
        let progress = CGFloat((currentPage ?? 0) + 1) / CGFloat(total)
        return ZStack(alignment: .leading) {
            Rectangle().fill(theme.foreground.opacity(0.12))
            Rectangle()
                .fill(Constants.Colors.accent)
                .frame(width: totalWidth * progress)
                .animation(.easeInOut(duration: 0.15), value: currentPage)
        }
        .frame(height: 2)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .red : .secondary)
            }
            
            ShareLink(
                item: "\"\(letter.title)\" — Seneca",
                preview: SharePreview(letter.title)
            )
            
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
                Image(systemName: "textformat")
            }
        }
        
        if letter.audioUrl != nil {
            ToolbarItemGroup(placement: .confirmationAction) {
                audioButton
            }
        }
    }
    
    // MARK: - Audio button
    
    private var audioButton: some View {
        Button {
            if isCurrentLetter {
                audioService.togglePlayPause()
            } else if let audioUrl = letter.audioUrl {
                audioService.load(urlString: audioUrl,
                                  title: "Letter \(letter.number)",
                                  subtitle: letter.title)
                audioService.togglePlayPause()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCurrentLetter && audioService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13))
                Text(isCurrentLetter && audioService.isPlaying ? "Pause" : "Listen")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Constants.Colors.accentLight)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Constants.Colors.accent, in: Capsule())
        }
    }
    
    // MARK: - Quote saved banner
    
    private var quoteSavedBanner: some View {
        Label("Quote saved", systemImage: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Constants.Colors.accent, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
        
        guard !text.isEmpty else {
            print("Попытка сохранить пустую цитату.")
            return
        }
        
        let quote = SavedQuote(
            text: text,
            letterTitle: letter.title,
            letterNumber: letter.number
        )
        modelContext.insert(quote)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(duration: 0.3)) { showQuoteSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) { showQuoteSaved = false }
        }
        
        NotificationManager.shared.scheladuleDailyQuoteNotification(modelContext: modelContext)
    }

    // MARK: - Save reading progress

    private func saveProgress(_ page: Int) {
        if let existing = allProgress.first(where: { $0.letterId == letter.id }) {
            existing.page = page
            existing.updatedAt = Date()
        } else {
            modelContext.insert(ReadingProgress(letterId: letter.id, page: page))
        }
    }

}
