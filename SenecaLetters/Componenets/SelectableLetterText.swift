//
//  SelectableLetterText.swift
//  SenecaLetters
//
//  UIViewRepresentable wrapping UITextView.
//  Adds "Save Quote" to the native iOS selection menu (iOS 16+).
//  Highlights already-saved quotes with the accent background color.
//  Accepts fontSize and theme so the paged reader can control typography.
//

import SwiftUI
import UIKit

// MARK: - UIKit colors for ReaderTheme (used here and in TextPaginator)

extension Constants.ReaderTheme {
    var uiBackground: UIColor {
        switch self {
        case .light: return .systemBackground
        case .sepia: return UIColor(red: 0.98, green: 0.94, blue: 0.90, alpha: 1)
        case .dark:  return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
        }
    }
    var uiForeground: UIColor {
        switch self {
        case .light: return .label
        case .sepia: return UIColor(red: 0.20, green: 0.14, blue: 0.08, alpha: 1)
        case .dark:  return UIColor(red: 0.88, green: 0.86, blue: 0.82, alpha: 1)
        }
    }
}

// MARK: - SelectableLetterText

struct SelectableLetterText: UIViewRepresentable {
    let content: String
    let savedQuoteTexts: [String]
    let fontSize: CGFloat
    let theme: Constants.ReaderTheme
    let onSaveQuote: (String) -> Void

    // #FAEEDA — accentLight
    private static let highlightBackground = UIColor(red: 0.98, green: 0.93, blue: 0.85, alpha: 1)
    // #854F0B — accent
    private static let highlightForeground = UIColor(red: 0.52, green: 0.31, blue: 0.04, alpha: 1)

    func makeCoordinator() -> Coordinator {
        Coordinator(onSaveQuote: onSaveQuote)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = theme.uiBackground
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 24, bottom: 24, right: 24)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        textView.attributedText = styledText(content, highlights: savedQuoteTexts)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.onSaveQuote = onSaveQuote
        guard content != context.coordinator.lastContent
           || savedQuoteTexts != context.coordinator.lastQuoteTexts
           || fontSize != context.coordinator.lastFontSize
           || theme != context.coordinator.lastTheme
        else { return }
        context.coordinator.lastContent = content
        context.coordinator.lastQuoteTexts = savedQuoteTexts
        context.coordinator.lastFontSize = fontSize
        context.coordinator.lastTheme = theme
        uiView.backgroundColor = theme.uiBackground
        uiView.attributedText = styledText(content, highlights: savedQuoteTexts)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 320
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    // MARK: - Attributed string with saved-quote highlights

    private func styledText(_ text: String, highlights: [String]) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        let font = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)

        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: theme.uiForeground
        ])

        let nsText = text as NSString
        for quote in highlights where !quote.isEmpty {
            var searchStart = 0
            while searchStart < nsText.length {
                let searchRange = NSRange(location: searchStart, length: nsText.length - searchStart)
                let found = nsText.range(of: quote, options: [], range: searchRange)
                guard found.location != NSNotFound else { break }
                attributed.addAttributes([
                    .backgroundColor: Self.highlightBackground,
                    .foregroundColor: Self.highlightForeground
                ], range: found)
                searchStart = found.location + found.length
            }
        }

        return attributed
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var onSaveQuote: (String) -> Void
        var lastContent: String = ""
        var lastQuoteTexts: [String] = []
        var lastFontSize: CGFloat = 17
        var lastTheme: Constants.ReaderTheme = .light

        init(onSaveQuote: @escaping (String) -> Void) {
            self.onSaveQuote = onSaveQuote
        }

        func textView(
            _ textView: UITextView,
            editMenuForTextIn range: NSRange,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            guard range.length > 0 else { return UIMenu(children: suggestedActions) }
            let selected = (textView.text as NSString).substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !selected.isEmpty else { return UIMenu(children: suggestedActions) }

            let saveAction = UIAction(
                title: "Save Quote",
                image: UIImage(systemName: "quote.bubble")
            ) { [weak self] _ in
                self?.onSaveQuote(selected)
            }
            return UIMenu(children: [saveAction] + suggestedActions)
        }
    }
}
