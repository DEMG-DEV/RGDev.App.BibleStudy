import SwiftUI

public struct RedLetterText: View {
    public let rawText: String
    public let isRedLetterEnabled: Bool
    public let fontSize: Double
    public let fontDesign: ReaderFontDesign

    public init(
        rawText: String,
        isRedLetterEnabled: Bool = true,
        fontSize: Double = 16.0,
        fontDesign: ReaderFontDesign = .serif
    ) {
        self.rawText = rawText
        self.isRedLetterEnabled = isRedLetterEnabled
        self.fontSize = fontSize
        self.fontDesign = fontDesign
    }

    public var body: some View {
        renderAttributedString()
            .lineSpacing(4)
    }

    private func renderAttributedString() -> Text {
        // Parse <wj>...</wj> fragments
        let parts = rawText.components(separatedBy: "<wj>")
        var combinedText = Text("")

        for (index, part) in parts.enumerated() {
            if index == 0 {
                // Leading narrator text
                if !part.isEmpty {
                    combinedText = combinedText + Text(part).foregroundColor(.primary)
                }
            } else {
                let subParts = part.components(separatedBy: "</wj>")
                let jesusWords = subParts[0]
                let trailingText = subParts.count > 1 ? subParts[1] : ""

                // Red Letter color (Apple HIG crimson/terracotta: readable in both light and dark mode)
                let redColor = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                    if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                        return NSColor(red: 1.0, green: 0.38, blue: 0.34, alpha: 1.0) // Soft coral crimson
                    } else {
                        return NSColor(red: 0.75, green: 0.15, blue: 0.12, alpha: 1.0) // Deep royal crimson
                    }
                }))

                if isRedLetterEnabled {
                    combinedText = combinedText + Text(jesusWords).foregroundColor(redColor)
                } else {
                    combinedText = combinedText + Text(jesusWords).foregroundColor(.primary)
                }

                if !trailingText.isEmpty {
                    combinedText = combinedText + Text(trailingText).foregroundColor(.primary)
                }
            }
        }

        return combinedText
            .font(selectedFont())
    }

    private func selectedFont() -> Font {
        switch fontDesign {
        case .serif:
            return Font.system(size: fontSize, weight: .regular, design: .serif)
        case .sans:
            return Font.system(size: fontSize, weight: .regular, design: .default)
        }
    }
}
