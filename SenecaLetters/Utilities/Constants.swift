//
//  Constants.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import Foundation
import SwiftUI

enum Constants {

    static let baseURL = "http://localhost:8080"
    static let apiURL = "\(baseURL)/api"

    enum Colors {
        static let accent = Color(red: 0.52, green: 0.31, blue: 0.04) // #854F0B
        static let accentLight = Color(red: 0.98, green: 0.93, blue: 0.85) // #FAEEDA
    }

    enum Fonts {
        static func serif(_ size: CGFloat) -> Font {
            .custom("Georgia", size: size)
        }

        static func serifBold(_ size: CGFloat) -> Font {
            .custom("Georgia-Bold", size: size)
        }
    }

    enum ReaderTheme: String, CaseIterable {
        case light, sepia, dark

        var background: Color {
            switch self {
            case .light: return Color(.systemBackground)
            case .sepia: return Color(red: 0.98, green: 0.94, blue: 0.90)
            case .dark:  return Color(red: 0.10, green: 0.10, blue: 0.10)
            }
        }

        var foreground: Color {
            switch self {
            case .light: return Color(.label)
            case .sepia: return Color(red: 0.20, green: 0.14, blue: 0.08)
            case .dark:  return Color(red: 0.88, green: 0.86, blue: 0.82)
            }
        }

        var iconName: String {
            switch self {
            case .light: return "sun.max"
            case .sepia: return "book"
            case .dark:  return "moon"
            }
        }
    }
}
