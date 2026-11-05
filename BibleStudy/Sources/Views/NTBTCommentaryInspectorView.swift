import SwiftUI
import AppKit

public struct NTBTCommentarySection: Identifiable {
    public var id: String { title }
    public let title: String
    public let icon: String
    public let contentHtml: String
    public let plainText: String
}

public struct NTBTCommentaryInspectorView: View {
    @ObservedObject var appState: AppState
    @State private var selectedVerseTab: Int = 1
    @State private var isIntroPresented: Bool = false

    private var activeVerseNumber: Int {
        if let h = appState.highlightedVerseNumber {
            return h
        }
        if let f = appState.selectedVerseNumbers.sorted().first {
            return f
        }
        return appState.sortedVerseNumbers.first ?? 1
    }

    private var commentary: NTBTCommentary? {
        appState.currentChapterCommentaries[activeVerseNumber]
    }

    private var ntbtVerseText: String? {
        appState.currentParallelVerses[activeVerseNumber]?["NTBT"]?.text
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Commentary Sub-Header with Verse Navigation
            verseNavigationBar

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Current Verse Card (With Red Letter Words)
                    currentVerseCard

                    if let comm = commentary {
                        // Title banner
                        if let title = comm.title ?? extractH2(from: comm.commentaryHtml) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)

                                if let sub = comm.subtitle, !sub.isEmpty {
                                    Text(sub)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        // Structured Sections
                        let sections = parseSections(from: comm.commentaryHtml)
                        ForEach(sections) { sec in
                            sectionCard(sec)
                        }

                        // Attribution Notice
                        attributionBanner
                    } else {
                        emptyCommentaryView
                    }
                }
                .padding(14)
            }
        }
    }

    private var verseNavigationBar: some View {
        HStack(spacing: 8) {
            // Previous verse
            Button {
                if activeVerseNumber > 1 {
                    appState.selectSingleVerse(activeVerseNumber - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(activeVerseNumber <= 1)

            Spacer()

            // Reference label
            Text("\(appState.selectedBook.name) \(appState.selectedChapter):\(activeVerseNumber)")
                .font(.system(size: 12, weight: .bold))

            Spacer()

            // Next verse
            let maxVerse = appState.sortedVerseNumbers.last ?? 1
            Button {
                if activeVerseNumber < maxVerse {
                    appState.selectSingleVerse(activeVerseNumber + 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(activeVerseNumber >= maxVerse)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
    }

    private var currentVerseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NTBT • Versículo \(activeVerseNumber)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentColor)
                    .textCase(.uppercase)

                Spacer()

                // Copy verse
                Button {
                    if let txt = ntbtVerseText {
                        let clean = txt.replacingOccurrences(of: "<wj>", with: "").replacingOccurrences(of: "</wj>", with: "")
                        let full = "«\(clean)» — \(appState.selectedBook.name) \(appState.selectedChapter):\(activeVerseNumber) (NTBT)"
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(full, forType: .string)
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copiar versículo")
            }

            if let txt = ntbtVerseText {
                RedLetterText(
                    rawText: txt,
                    isRedLetterEnabled: appState.isRedLetterEnabled,
                    fontSize: 13,
                    fontDesign: appState.fontDesign
                )
            } else {
                Text("Cargando texto de la versión NTBT...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func sectionCard(_ sec: NTBTCommentarySection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: sec.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)

                Text(sec.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }

            Text(cleanHtmlText(sec.contentHtml))
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.88))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private var attributionBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.vertical, 8)

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
        .padding(.horizontal, 4)
    }

    private var emptyCommentaryView: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Comentario no disponible para este versículo.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - HTML Parsing Helpers

    private func extractH2(from html: String) -> String? {
        if let match = html.range(of: "(?<=<h2>).*?(?=</h2>)", options: .regularExpression) {
            return String(html[match]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private func parseSections(from html: String) -> [NTBTCommentarySection] {
        var sections: [NTBTCommentarySection] = []

        // Extract initial overview paragraph before the first h3
        var working = html
        if let firstH2End = working.range(of: "</h2>")?.upperBound {
            working = String(working[firstH2End...])
        }

        if let firstH3Start = working.range(of: "<h3>")?.lowerBound {
            let overview = String(working[..<firstH3Start])
            let clean = cleanHtmlText(overview).trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                sections.append(NTBTCommentarySection(
                    title: "Resumen Exegético",
                    icon: "lightbulb.fill",
                    contentHtml: overview,
                    plainText: clean
                ))
            }
            working = String(working[firstH3Start...])
        } else {
            let clean = cleanHtmlText(working).trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                sections.append(NTBTCommentarySection(
                    title: "Explicación",
                    icon: "book.fill",
                    contentHtml: working,
                    plainText: clean
                ))
            }
            return sections
        }

        // Split by <h3>
        let h3Pattern = #"<h3>(.*?)</h3>(.*?)(?=(?:<h3>|$))"#
        if let regex = try? NSRegularExpression(pattern: h3Pattern, options: [.dotMatchesLineSeparators]) {
            let nsWorking = working as NSString
            let matches = regex.matches(in: working, options: [], range: NSRange(location: 0, length: nsWorking.length))

            for match in matches {
                guard match.numberOfRanges >= 3 else { continue }
                let title = nsWorking.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let body = nsWorking.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                let clean = cleanHtmlText(body)

                var icon = "doc.text.fill"
                let lowerTitle = title.lowercased()
                if lowerTitle.contains("explicaci") {
                    icon = "text.alignleft"
                } else if lowerTitle.contains("original") || lowerTitle.contains("exég") || lowerTitle.contains("exeg") {
                    icon = "character.book.closed.fill"
                } else if lowerTitle.contains("relaci") || lowerTitle.contains("bíb") || lowerTitle.contains("bib") {
                    icon = "link"
                } else if lowerTitle.contains("aplica") {
                    icon = "heart.text.square.fill"
                }

                sections.append(NTBTCommentarySection(
                    title: title,
                    icon: icon,
                    contentHtml: body,
                    plainText: clean
                ))
            }
        }

        return sections
    }

    private func cleanHtmlText(_ html: String) -> String {
        var str = html
            .replacingOccurrences(of: "<br/?>", with: "\n", options: .regularExpression)
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

        // Collapse multiple blank lines
        str = str.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
