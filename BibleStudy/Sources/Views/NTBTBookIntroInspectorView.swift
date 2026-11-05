import SwiftUI

public struct NTBTBookIntroInspectorView: View {
    @ObservedObject var appState: AppState

    private var intro: NTBTBookIntro? {
        appState.currentBookIntro
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header badge
                HStack {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.accentColor)

                    Text("NTBT • Introducción Canónica")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                        .textCase(.uppercase)

                    Spacer()
                }

                if let bookIntro = intro {
                    Text(cleanHtmlText(bookIntro.introHtml))
                        .font(.system(size: 13, design: appState.fontDesign == .serif ? .serif : .default))
                        .lineSpacing(4)
                        .foregroundColor(.primary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Introducción no disponible para este libro.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                Divider()
                    .padding(.vertical, 8)

                // Attribution
                VStack(alignment: .leading, spacing: 4) {
                    Text("Santa Biblia, Nueva Traducción BibliaTodo (NTBT).")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("Publicada por")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)

                        Link("BibliaTodo Bible Society", destination: URL(string: "https://www.bibliatodo.com/ntbt/")!)
                            .font(.system(size: 9, weight: .medium))
                    }
                }
            }
            .padding(14)
        }
    }

    private func cleanHtmlText(_ html: String) -> String {
        var str = html
            .replacingOccurrences(of: "<br/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</h2>", with: "\n\n")
            .replacingOccurrences(of: "</h3>", with: "\n\n")
            .replacingOccurrences(of: "</p>", with: "\n\n")
            .replacingOccurrences(of: "</li>", with: "\n")
            .replacingOccurrences(of: "<li>", with: "• ")

        str = str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        str = str
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")

        str = str.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
