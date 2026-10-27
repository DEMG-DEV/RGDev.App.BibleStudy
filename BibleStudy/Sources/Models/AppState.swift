import SwiftUI
import Combine

public enum ReaderFontDesign: String, CaseIterable, Identifiable {
    case serif = "Serif (New York)"
    case sans = "Sans-Serif (SF Pro)"

    public var id: String { rawValue }
}

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "Automático (Sistema)"
    case light = "Claro"
    case dark = "Oscuro"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    public var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    @Published public var allBooks: [BibleBook] = []
    @Published public var selectedBook: BibleBook
    @Published public var selectedChapter: Int = 1
    @Published public var highlightedVerseNumber: Int? = nil
    @Published public var selectedVerseNumbers: Set<Int> = []
    public var selectionAnchorVerse: Int? = nil

    @Published public var activeVersions: [String] = ["RVR1960", "NTV"]
    public let availableVersions: [String] = ["RVR1960", "NTV", "TLA", "NVI"]

    @Published public var isRedLetterEnabled: Bool = true
    @Published public var fontSize: Double = 16.0
    @Published public var fontDesign: ReaderFontDesign = .serif

    @Published public var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    @Published public var isNotesInspectorPresented: Bool = true
    @Published public var selectedNoteForEditing: StudyNote? = nil
    @Published public var isCreatingNewNote: Bool = false

    @Published public var searchQuery: String = ""
    @Published public var searchResults: [SearchResult] = []
    @Published public var isSearching: Bool = false

    @Published public var currentParallelVerses: [Int: [String: BibleVerse]] = [:]
    @Published public var sortedVerseNumbers: [Int] = []

    public init() {
        // Load saved theme or default to system
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }

        let books = BibleDatabase.shared.fetchAllBooks()
        self.allBooks = books

        // Default to Juan (Book 43) or first book
        if let juan = books.first(where: { $0.id == 43 }) {
            self.selectedBook = juan
            self.selectedChapter = 3
            self.highlightedVerseNumber = 16
            self.selectedVerseNumbers = [16]
            self.selectionAnchorVerse = 16
        } else if let first = books.first {
            self.selectedBook = first
            self.selectedChapter = 1
            self.selectedVerseNumbers = []
        } else {
            // Fallback placeholder
            self.selectedBook = BibleBook(
                id: 43,
                testament: .newTestament,
                category: "Evangelios",
                name: "Juan",
                usfm: "JHN",
                abbreviation: "Jn",
                totalChapters: 21
            )
        }

        loadCurrentChapter()
    }

    public func toggleTheme() {
        switch currentTheme {
        case .system:
            currentTheme = .light
        case .light:
            currentTheme = .dark
        case .dark:
            currentTheme = .system
        }
    }

    public func loadCurrentChapter() {
        let parallel = BibleDatabase.shared.fetchParallelVerses(
            bookNumber: selectedBook.id,
            chapter: selectedChapter,
            versions: activeVersions
        )
        self.currentParallelVerses = parallel
        self.sortedVerseNumbers = parallel.keys.sorted()
    }

    public func toggleVersion(_ vid: String) {
        if activeVersions.contains(vid) {
            if activeVersions.count > 1 {
                activeVersions.removeAll(where: { $0 == vid })
            }
        } else {
            activeVersions.append(vid)
            // Keep consistent order: RVR1960, NTV, TLA, NVI
            let order = ["RVR1960", "NTV", "TLA", "NVI"]
            activeVersions.sort {
                (order.firstIndex(of: $0) ?? 0) < (order.firstIndex(of: $1) ?? 0)
            }
        }
        loadCurrentChapter()
    }

    public func jumpTo(book: BibleBook, chapter: Int, verse: Int? = nil) {
        self.selectedBook = book
        self.selectedChapter = min(max(1, chapter), book.totalChapters)
        if let v = verse {
            self.highlightedVerseNumber = v
            self.selectedVerseNumbers = [v]
            self.selectionAnchorVerse = v
        } else {
            self.highlightedVerseNumber = nil
            self.selectedVerseNumbers.removeAll()
            self.selectionAnchorVerse = nil
        }
        loadCurrentChapter()
    }

    public static func formatVerseNumbers(_ verses: Set<Int>) -> String {
        let sorted = verses.sorted()
        guard !sorted.isEmpty else { return "" }
        var ranges: [ClosedRange<Int>] = []
        for v in sorted {
            if let last = ranges.last, last.upperBound == v - 1 {
                ranges[ranges.count - 1] = last.lowerBound...v
            } else {
                ranges.append(v...v)
            }
        }
        return ranges.map { r in
            r.lowerBound == r.upperBound ? "\(r.lowerBound)" : "\(r.lowerBound)-\(r.upperBound)"
        }.joined(separator: ", ")
    }

    public var selectedVersesReference: String {
        let targetVerses = !selectedVerseNumbers.isEmpty ? selectedVerseNumbers : (highlightedVerseNumber != nil ? [highlightedVerseNumber!] : [])
        guard !targetVerses.isEmpty else {
            return "\(selectedBook.name) \(selectedChapter)"
        }
        return "\(selectedBook.name) \(selectedChapter):\(Self.formatVerseNumbers(targetVerses))"
    }

    public func selectSingleVerse(_ vnum: Int) {
        selectedVerseNumbers = [vnum]
        selectionAnchorVerse = vnum
        highlightedVerseNumber = vnum
    }

    public func toggleVerse(_ vnum: Int) {
        if selectedVerseNumbers.contains(vnum) {
            selectedVerseNumbers.remove(vnum)
            if highlightedVerseNumber == vnum {
                highlightedVerseNumber = selectedVerseNumbers.sorted().first
            }
        } else {
            selectedVerseNumbers.insert(vnum)
            selectionAnchorVerse = vnum
            highlightedVerseNumber = vnum
        }
    }

    public func handleVerseClick(_ vnum: Int, isShift: Bool, isCommand: Bool) {
        if isShift {
            let anchor = selectionAnchorVerse ?? highlightedVerseNumber ?? vnum
            let low = min(anchor, vnum)
            let high = max(anchor, vnum)
            for v in low...high {
                selectedVerseNumbers.insert(v)
            }
            highlightedVerseNumber = vnum
        } else if isCommand {
            toggleVerse(vnum)
        } else {
            selectSingleVerse(vnum)
        }
    }

    public func clearVerseSelection() {
        selectedVerseNumbers.removeAll()
        highlightedVerseNumber = nil
        selectionAnchorVerse = nil
    }

    public func selectAllVersesInChapter() {
        selectedVerseNumbers = Set(sortedVerseNumbers)
        highlightedVerseNumber = sortedVerseNumbers.first
    }

    public func selectedVersesPlainText(versionId: String? = nil) -> String {
        let vid = versionId ?? activeVersions.first ?? "RVR1960"
        let sortedVnums = selectedVerseNumbers.sorted()
        var lines: [String] = []
        for v in sortedVnums {
            if let verseObj = currentParallelVerses[v]?[vid] {
                let clean = verseObj.text
                    .replacingOccurrences(of: "<wj>", with: "")
                    .replacingOccurrences(of: "</wj>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                lines.append("\(v) \(clean)")
            }
        }
        return lines.joined(separator: "\n")
    }

    public func executeSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        // 1. Try citation parsing first (e.g. "jn 3:16", "salmos 23")
        if let citation = BibleDatabase.shared.parseCitation(input: query, books: allBooks) {
            jumpTo(book: citation.book, chapter: citation.chapter, verse: citation.verse)
            isSearching = false
            return
        }

        // 2. Full-Text Search in first active version or RVR1960
        let targetVersion = activeVersions.first ?? "RVR1960"
        self.searchResults = BibleDatabase.shared.searchFTS(query: query, versionId: targetVersion, limit: 60)
    }

    public func createNoteForCurrentSelection(verseNumber: Int? = nil) {
        let targetVerses: [Int]
        if let v = verseNumber {
            targetVerses = [v]
        } else if !selectedVerseNumbers.isEmpty {
            targetVerses = selectedVerseNumbers.sorted()
        } else if let h = highlightedVerseNumber {
            targetVerses = [h]
        } else {
            targetVerses = [1]
        }

        let startVerse = targetVerses.first ?? 1
        let cid = (selectedBook.id * 1_000_000) + (selectedChapter * 1_000) + startVerse
        let formattedRange = Self.formatVerseNumbers(Set(targetVerses))
        let refStr = "\(selectedBook.name) \(selectedChapter):\(formattedRange)"
        let primaryVersion = activeVersions.first ?? "RVR1960"
        let versionsUsedStr = activeVersions.joined(separator: " / ")

        var initialContent = ""
        var quotes: [String] = []
        for v in targetVerses {
            if let verseObj = currentParallelVerses[v]?[primaryVersion] {
                let clean = verseObj.text
                    .replacingOccurrences(of: "<wj>", with: "")
                    .replacingOccurrences(of: "</wj>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                quotes.append("[\(v)] \(clean)")
            }
        }

        if !quotes.isEmpty {
            initialContent = "«" + quotes.joined(separator: "\n") + "» (\(primaryVersion))\n\n"
        }

        let summaryStr = targetVerses.count > 1 ? "\(targetVerses.count) versículos seleccionados" : (quotes.first ?? "")

        let newNote = StudyNote(
            canonicalVerseId: cid,
            verseReference: refStr,
            versionUsed: versionsUsedStr,
            topic: "Reflexión",
            summary: summaryStr,
            content: initialContent
        )
        self.selectedNoteForEditing = newNote
        self.isCreatingNewNote = true
        self.isNotesInspectorPresented = true
    }
}
