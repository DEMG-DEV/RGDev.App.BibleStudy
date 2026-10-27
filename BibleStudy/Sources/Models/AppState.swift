import SwiftUI
import Combine

public enum ReaderFontDesign: String, CaseIterable, Identifiable {
    case serif = "Serif (New York)"
    case sans = "Sans-Serif (SF Pro)"

    public var id: String { rawValue }
}

@MainActor
public final class AppState: ObservableObject {
    @Published public var allBooks: [BibleBook] = []
    @Published public var selectedBook: BibleBook
    @Published public var selectedChapter: Int = 1
    @Published public var highlightedVerseNumber: Int? = nil

    @Published public var activeVersions: [String] = ["RVR1960", "NTV"]
    public let availableVersions: [String] = ["RVR1960", "NTV", "TLA", "NVI"]

    @Published public var isRedLetterEnabled: Bool = true
    @Published public var fontSize: Double = 16.0
    @Published public var fontDesign: ReaderFontDesign = .serif

    @Published public var isNotesInspectorPresented: Bool = true
    @Published public var selectedNoteForEditing: StudyNote? = nil
    @Published public var isCreatingNewNote: Bool = false

    @Published public var searchQuery: String = ""
    @Published public var searchResults: [SearchResult] = []
    @Published public var isSearching: Bool = false

    @Published public var currentParallelVerses: [Int: [String: BibleVerse]] = [:]
    @Published public var sortedVerseNumbers: [Int] = []

    public init() {
        let books = BibleDatabase.shared.fetchAllBooks()
        self.allBooks = books

        // Default to Juan (Book 43) or first book
        if let juan = books.first(where: { $0.id == 43 }) {
            self.selectedBook = juan
            self.selectedChapter = 3
            self.highlightedVerseNumber = 16
        } else if let first = books.first {
            self.selectedBook = first
            self.selectedChapter = 1
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
        self.highlightedVerseNumber = verse
        loadCurrentChapter()
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
        let targetVerse = verseNumber ?? highlightedVerseNumber ?? 1
        let cid = (selectedBook.id * 1_000_000) + (selectedChapter * 1_000) + targetVerse
        let refStr = "\(selectedBook.name) \(selectedChapter):\(targetVerse)"
        let versionsUsedStr = activeVersions.joined(separator: " / ")

        let newNote = StudyNote(
            canonicalVerseId: cid,
            verseReference: refStr,
            versionUsed: versionsUsedStr,
            topic: "Reflexión",
            summary: "",
            content: ""
        )
        self.selectedNoteForEditing = newNote
        self.isCreatingNewNote = true
        self.isNotesInspectorPresented = true
    }
}
