//
//  TextPaginator.swift
//  SenecaLetters
//

import UIKit

enum TextPaginator {

    /// Splits `attributedText` into page-sized strings using TextKit 1.
    /// All text is laid out in a single infinite-height container; then
    /// line-fragment rects are walked to find page breaks.
    ///
    /// - Parameters:
    ///   - attributedText: Fully styled string matching what SelectableLetterText renders.
    ///   - pageSize: Available text area per page (UITextView insets already excluded).
    static func paginate(attributedText: NSAttributedString, pageSize: CGSize) -> [String] {
        guard attributedText.length > 0, pageSize.width > 0, pageSize.height > 0 else {
            return attributedText.length > 0 ? [attributedText.string] : []
        }

        let storage = NSTextStorage(attributedString: attributedText)
        let manager = NSLayoutManager()
        storage.addLayoutManager(manager)

        // Single infinite-height container so the manager lays out all glyphs at once.
        let container = NSTextContainer(size: CGSize(width: pageSize.width,
                                                     height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        manager.ensureLayout(for: container)

        var pages: [String] = []
        let totalGlyphs = manager.numberOfGlyphs
        var startGlyph = 0
        var pageOriginY: CGFloat = 0  // absolute Y of the top of the current page

        while startGlyph < totalGlyphs {
            var endGlyph = startGlyph

            // Advance line-fragment by line-fragment until the next one would overflow.
            while endGlyph < totalGlyphs {
                var lineRange = NSRange()
                let lineRect = manager.lineFragmentRect(forGlyphAt: endGlyph,
                                                        effectiveRange: &lineRange)
                if (lineRect.maxY - pageOriginY) > pageSize.height { break }
                endGlyph = NSMaxRange(lineRange)
            }

            // Guard: include at least one line to avoid an infinite loop on oversized lines.
            if endGlyph == startGlyph {
                var lineRange = NSRange()
                manager.lineFragmentRect(forGlyphAt: startGlyph, effectiveRange: &lineRange)
                endGlyph = NSMaxRange(lineRange)
            }

            let glyphRange = NSRange(location: startGlyph, length: endGlyph - startGlyph)
            let charRange  = manager.characterRange(forGlyphRange: glyphRange,
                                                    actualGlyphRange: nil)
            pages.append((storage.string as NSString).substring(with: charRange))

            // Advance the page origin to the top of the next line.
            startGlyph = endGlyph
            if startGlyph < totalGlyphs {
                var nextRange = NSRange()
                let nextRect  = manager.lineFragmentRect(forGlyphAt: startGlyph,
                                                         effectiveRange: &nextRange)
                pageOriginY = nextRect.minY
            }
        }

        return pages.isEmpty ? [attributedText.string] : pages
    }

    /// Builds an NSAttributedString with the same typography as SelectableLetterText.
    static func buildAttributedString(text: String,
                                      fontSize: CGFloat,
                                      theme: Constants.ReaderTheme) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 10
        let font = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .paragraphStyle: style,
            .foregroundColor: theme.uiForeground   // extension in SelectableLetterText.swift
        ])
    }
}
