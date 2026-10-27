import Foundation
import SQLite3

public final class BibleDatabase: @unchecked Sendable {
    public static let shared = BibleDatabase()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.rgdev.biblestudy.db", qos: .userInitiated)

    private init() {
        openDatabase()
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    private func openDatabase() {
        var dbPath: String?

        // 1. Check Bundle.module resource
        #if SWIFT_PACKAGE
        if let bundlePath = Bundle.module.path(forResource: "Bibles", ofType: "sqlite") {
            dbPath = bundlePath
        }
        #endif

        // 2. Check main bundle
        if dbPath == nil {
            dbPath = Bundle.main.path(forResource: "Bibles", ofType: "sqlite")
        }

        // 3. Fallback to local development directory
        if dbPath == nil {
            let directPath = "BibleStudy/Sources/Resources/Bibles.sqlite"
            if FileManager.default.fileExists(atPath: directPath) {
                dbPath = directPath
            }
        }

        guard let path = dbPath else {
            print("❌ BibleDatabase: Bibles.sqlite not found.")
            return
        }

        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            print("✅ BibleDatabase: Opened database successfully at \(path)")
        } else {
            print("❌ BibleDatabase: Failed to open SQLite at \(path)")
        }
    }

    public func fetchAllBooks() -> [BibleBook] {
        guard let db = db else { return [] }
        var result: [BibleBook] = []

        let query = "SELECT book_number, testament, category, name, usfm, abbreviation, total_chapters FROM books ORDER BY book_number ASC;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                let testStr = String(cString: sqlite3_column_text(stmt, 1))
                let cat = String(cString: sqlite3_column_text(stmt, 2))
                let name = String(cString: sqlite3_column_text(stmt, 3))
                let usfm = String(cString: sqlite3_column_text(stmt, 4))
                let abbr = String(cString: sqlite3_column_text(stmt, 5))
                let totCh = Int(sqlite3_column_int(stmt, 6))

                let testament = (testStr == "NT") ? Testament.newTestament : Testament.oldTestament
                let book = BibleBook(
                    id: id,
                    testament: testament,
                    category: cat,
                    name: name,
                    usfm: usfm,
                    abbreviation: abbr,
                    totalChapters: totCh
                )
                result.append(book)
            }
        }
        sqlite3_finalize(stmt)
        return result
    }

    public func fetchVerses(versionId: String, bookNumber: Int, chapter: Int) -> [BibleVerse] {
        guard let db = db else { return [] }
        var verses: [BibleVerse] = []

        let query = """
        SELECT canonical_id, version_id, book_number, chapter, verse, text, heading
        FROM verses
        WHERE version_id = ? AND book_number = ? AND chapter = ?
        ORDER BY verse ASC;
        """
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (versionId as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(bookNumber))
            sqlite3_bind_int(stmt, 3, Int32(chapter))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let cid = Int(sqlite3_column_int(stmt, 0))
                let vid = String(cString: sqlite3_column_text(stmt, 1))
                let bnum = Int(sqlite3_column_int(stmt, 2))
                let ch = Int(sqlite3_column_int(stmt, 3))
                let v = Int(sqlite3_column_int(stmt, 4))
                let txt = String(cString: sqlite3_column_text(stmt, 5))
                var head: String? = nil
                if let cHead = sqlite3_column_text(stmt, 6) {
                    head = String(cString: cHead)
                }

                verses.append(BibleVerse(
                    canonicalId: cid,
                    versionId: vid,
                    bookNumber: bnum,
                    chapter: ch,
                    verse: v,
                    text: txt,
                    heading: head
                ))
            }
        }
        sqlite3_finalize(stmt)
        return verses
    }

    public func fetchParallelVerses(bookNumber: Int, chapter: Int, versions: [String]) -> [Int: [String: BibleVerse]] {
        guard let db = db, !versions.isEmpty else { return [:] }
        var map: [Int: [String: BibleVerse]] = [:]

        let placeholders = Array(repeating: "?", count: versions.count).joined(separator: ", ")
        let query = """
        SELECT canonical_id, version_id, book_number, chapter, verse, text, heading
        FROM verses
        WHERE book_number = ? AND chapter = ? AND version_id IN (\(placeholders))
        ORDER BY verse ASC, version_id ASC;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(bookNumber))
            sqlite3_bind_int(stmt, 2, Int32(chapter))

            for (index, v) in versions.enumerated() {
                sqlite3_bind_text(stmt, Int32(3 + index), (v as NSString).utf8String, -1, nil)
            }

            while sqlite3_step(stmt) == SQLITE_ROW {
                let cid = Int(sqlite3_column_int(stmt, 0))
                let vid = String(cString: sqlite3_column_text(stmt, 1))
                let bnum = Int(sqlite3_column_int(stmt, 2))
                let ch = Int(sqlite3_column_int(stmt, 3))
                let v = Int(sqlite3_column_int(stmt, 4))
                let txt = String(cString: sqlite3_column_text(stmt, 5))
                var head: String? = nil
                if let cHead = sqlite3_column_text(stmt, 6) {
                    head = String(cString: cHead)
                }

                let verseObj = BibleVerse(
                    canonicalId: cid,
                    versionId: vid,
                    bookNumber: bnum,
                    chapter: ch,
                    verse: v,
                    text: txt,
                    heading: head
                )

                if map[v] == nil {
                    map[v] = [:]
                }
                map[v]?[vid] = verseObj
            }
        }
        sqlite3_finalize(stmt)
        return map
    }

    public func searchFTS(query: String, versionId: String = "RVR1960", limit: Int = 50) -> [SearchResult] {
        guard let db = db, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var results: [SearchResult] = []

        // Format query for FTS5 (support prefix match and individual terms)
        let cleanedTerms = query.components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
            .map { "\"\($0)\"*" }
            .joined(separator: " AND ")

        guard !cleanedTerms.isEmpty else { return [] }

        let sql = """
        SELECT canonical_id, version_id, book_name, chapter, verse,
               snippet(verses_fts, 5, '<b>', '</b>', '...', 10) as snippet,
               text
        FROM verses_fts
        WHERE version_id = ? AND verses_fts MATCH ?
        LIMIT ?;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (versionId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (cleanedTerms as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 3, Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let cid = Int(sqlite3_column_int(stmt, 0))
                let vid = String(cString: sqlite3_column_text(stmt, 1))
                let bname = String(cString: sqlite3_column_text(stmt, 2))
                let ch = Int(sqlite3_column_int(stmt, 3))
                let v = Int(sqlite3_column_int(stmt, 4))
                let snip = String(cString: sqlite3_column_text(stmt, 5))
                let fullTxt = String(cString: sqlite3_column_text(stmt, 6))

                results.append(SearchResult(
                    canonicalId: cid,
                    versionId: vid,
                    bookName: bname,
                    chapter: ch,
                    verse: v,
                    snippet: snip,
                    fullText: fullTxt
                ))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }

    public func parseCitation(input: String, books: [BibleBook]) -> (book: BibleBook, chapter: Int, verse: Int?)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        // Pattern: [book name/abbreviation] [chapter](:[verse])?
        // Examples: "jn 3:16", "juan 3 16", "salmos 23", "1 co 13:4", "gen 1"
        let pattern = #"^((?:\d\s*)?[a-záéíóúñ]+)\s*(\d+)[\s:]*(\d*)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(location: 0, length: trimmed.utf16.count)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range) else {
            return nil
        }

        guard let bookRange = Range(match.range(at: 1), in: trimmed),
              let chapterRange = Range(match.range(at: 2), in: trimmed),
              let chapter = Int(trimmed[chapterRange]) else {
            return nil
        }

        let rawBook = String(trimmed[bookRange]).replacingOccurrences(of: " ", with: "")
        var verse: Int? = nil
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound,
           let verseRange = Range(match.range(at: 3), in: trimmed),
           let v = Int(trimmed[verseRange]) {
            verse = v
        }

        // Find matching book by abbreviation or name prefix
        if let foundBook = books.first(where: {
            $0.abbreviation.lowercased() == rawBook ||
            $0.name.lowercased().replacingOccurrences(of: " ", with: "").hasPrefix(rawBook)
        }) {
            let validChapter = max(1, min(chapter, foundBook.totalChapters))
            return (foundBook, validChapter, verse)
        }

        return nil
    }
}
