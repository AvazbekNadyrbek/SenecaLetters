//
//  LetterRow.swift
//  SenecaLetters
//
//  Created by Авазбек Надырбек уулу on 3/16/26.
//

import SwiftUI

struct LetterRow: View {
    
    let letter: Letter
    
    // Римские цифры для номеров
    private var romanNumber: String {
        let romans = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                      "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]
        let number = letter.number
        if number > 0 && number < romans.count {
            return romans[number]
        }
        return "\(number)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Римская цифра — золотой цвет
            Text(romanNumber)
                .font(Constants.Fonts.serif(22))
                .fontWeight(.medium)
                .foregroundStyle(Constants.Colors.accent)
                .frame(minWidth: 32, alignment: .leading)
            
            // Заголовок + превью текста
            VStack(alignment: .leading, spacing: 3) {
                Text(letter.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let summary = letter.summary {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
//            // Стрелка вправо
//            Image(systemName: "chevron.right")
//                .font(.system(size: 12, weight: .medium))
//                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
    }
}

//#Preview {
//    LetterRow()
//}
