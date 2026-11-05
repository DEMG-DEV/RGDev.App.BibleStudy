import Foundation
import SQLite3

public final class BibleDatabase: @unchecked Sendable {
    public static let shared = BibleDatabase()

    private var db: OpaquePointer?
    private var commentaryDb: OpaquePointer?

    private init() {
        openDatabase()
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
        if commentaryDb != nil {
            sqlite3_close(commentaryDb)
        }
    }

    private func openDatabase() {
        let fileManager = FileManager.default
        var dbPath: String?

        // Candidate paths for Bibles.sqlite
        let candidatePaths: [String?] = [
            Bundle.main.resourceURL?.appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/Bibles.sqlite").path,
            Bundle.main.bundleURL.appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/Bibles.sqlite").path,
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/Bibles.sqlite").path,
            Bundle.main.resourceURL?.appendingPathComponent("BibleStudy_BibleStudy.bundle/Bibles.sqlite").path,
            Bundle.main.bundleURL.appendingPathComponent("BibleStudy_BibleStudy.bundle/Bibles.sqlite").path,
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/Bibles.sqlite").path,
            Bundle.main.path(forResource: "Bibles", ofType: "sqlite"),
            "BibleStudy/Sources/Resources/Bibles.sqlite",
            "Sources/Resources/Bibles.sqlite",
            "/Users/devln/RGDev/RGDev.App.BibleStudy/BibleStudy/Sources/Resources/Bibles.sqlite"
        ]

        for pathOpt in candidatePaths {
            if let p = pathOpt, fileManager.fileExists(atPath: p) {
                dbPath = p
                break
            }
        }

        #if SWIFT_PACKAGE
        if dbPath == nil {
            if let bundlePath = Bundle.module.path(forResource: "Bibles", ofType: "sqlite") {
                dbPath = bundlePath
            }
        }
        #endif

        if let path = dbPath {
            if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
                print("✅ BibleDatabase: Opened Bibles database successfully at \(path)")
            } else {
                print("❌ BibleDatabase: Failed to open Bibles SQLite at \(path)")
            }
        } else {
            print("❌ BibleDatabase: Bibles.sqlite not found in any candidate path.")
        }

        // Candidate paths for NTBTCommentaries.sqlite
        var commPath: String?
        let commCandidatePaths: [String?] = [
            Bundle.main.resourceURL?.appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/NTBTCommentaries.sqlite").path,
            Bundle.main.bundleURL.appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/NTBTCommentaries.sqlite").path,
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/NTBTCommentaries.sqlite").path,
            Bundle.main.resourceURL?.appendingPathComponent("BibleStudy_BibleStudy.bundle/NTBTCommentaries.sqlite").path,
            Bundle.main.bundleURL.appendingPathComponent("BibleStudy_BibleStudy.bundle/NTBTCommentaries.sqlite").path,
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/NTBTCommentaries.sqlite").path,
            Bundle.main.path(forResource: "NTBTCommentaries", ofType: "sqlite"),
            "BibleStudy/Sources/Resources/NTBTCommentaries.sqlite",
            "Sources/Resources/NTBTCommentaries.sqlite",
            "/Users/devln/RGDev/RGDev.App.BibleStudy/BibleStudy/Sources/Resources/NTBTCommentaries.sqlite"
        ]

        for pathOpt in commCandidatePaths {
            if let p = pathOpt, fileManager.fileExists(atPath: p) {
                commPath = p
                break
            }
        }

        #if SWIFT_PACKAGE
        if commPath == nil {
            if let bundlePath = Bundle.module.path(forResource: "NTBTCommentaries", ofType: "sqlite") {
                commPath = bundlePath
            }
        }
        #endif

        if let cp = commPath {
            if sqlite3_open_v2(cp, &commentaryDb, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
                print("✅ BibleDatabase: Opened NTBT commentaries database successfully at \(cp)")
            } else {
                print("⚠️ BibleDatabase: Failed to open NTBT commentaries SQLite at \(cp)")
            }
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

        // Normalize diacritics: 'éxodo' -> 'exodo', 'génesis' -> 'genesis'
        let normalized = trimmed.folding(options: .diacriticInsensitive, locale: .current)

        // Pattern: [book name/abbreviation] [chapter](:[verse])?
        let pattern = #"^((?:\d\s*)?[a-z]+)\s*(\d+)[\s:]*(\d*)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(location: 0, length: normalized.utf16.count)
        guard let match = regex.firstMatch(in: normalized, options: [], range: range) else {
            return nil
        }

        guard let bookRange = Range(match.range(at: 1), in: normalized),
              let chapterRange = Range(match.range(at: 2), in: normalized),
              let chapter = Int(normalized[chapterRange]) else {
            return nil
        }

        let rawBook = String(normalized[bookRange]).replacingOccurrences(of: " ", with: "")
        var verse: Int? = nil
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound,
           let verseRange = Range(match.range(at: 3), in: normalized),
           let v = Int(normalized[verseRange]) {
            verse = v
        }

        // Find matching book by normalized abbreviation or name prefix
        if let foundBook = books.first(where: { book in
            let bookNorm = book.name.lowercased().folding(options: .diacriticInsensitive, locale: .current).replacingOccurrences(of: " ", with: "")
            let abbrNorm = book.abbreviation.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            return abbrNorm == rawBook || bookNorm.hasPrefix(rawBook)
        }) {
            let validChapter = max(1, min(chapter, foundBook.totalChapters))
            return (foundBook, validChapter, verse)
        }

        return nil
    }

    public func fetchNTBTCommentaries(bookNumber: Int, chapter: Int, verses: [Int] = []) -> [NTBTCommentary] {
        let activeDb = commentaryDb ?? db
        guard let dbToUse = activeDb else { return [] }
        var list: [NTBTCommentary] = []

        var query: String
        if verses.isEmpty {
            query = """
            SELECT canonical_id, book_number, chapter, verse, title, subtitle, commentary_data, references_text
            FROM ntbt_commentaries
            WHERE book_number = ? AND chapter = ?
            ORDER BY verse ASC;
            """
        } else {
            let placeholders = Array(repeating: "?", count: verses.count).joined(separator: ", ")
            query = """
            SELECT canonical_id, book_number, chapter, verse, title, subtitle, commentary_data, references_text
            FROM ntbt_commentaries
            WHERE book_number = ? AND chapter = ? AND verse IN (\(placeholders))
            ORDER BY verse ASC;
            """
        }

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(dbToUse, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(bookNumber))
            sqlite3_bind_int(stmt, 2, Int32(chapter))

            for (index, v) in verses.enumerated() {
                sqlite3_bind_int(stmt, Int32(3 + index), Int32(v))
            }

            while sqlite3_step(stmt) == SQLITE_ROW {
                let cid = Int(sqlite3_column_int(stmt, 0))
                let bnum = Int(sqlite3_column_int(stmt, 1))
                let ch = Int(sqlite3_column_int(stmt, 2))
                let v = Int(sqlite3_column_int(stmt, 3))

                var title: String? = nil
                if let cTitle = sqlite3_column_text(stmt, 4) {
                    title = String(cString: cTitle)
                }

                var subtitle: String? = nil
                if let cSub = sqlite3_column_text(stmt, 5) {
                    subtitle = String(cString: cSub)
                }

                var html = ""
                let colType = sqlite3_column_type(stmt, 6)
                if colType == SQLITE_BLOB {
                    if let blobBytes = sqlite3_column_blob(stmt, 6) {
                        let count = Int(sqlite3_column_bytes(stmt, 6))
                        let compressed = Data(bytes: blobBytes, count: count)
                        if let decompressed = try? (compressed as NSData).decompressed(using: .zlib) as Data,
                           let str = String(data: decompressed, encoding: .utf8) {
                            html = str
                        }
                    }
                } else if let cHtml = sqlite3_column_text(stmt, 6) {
                    html = String(cString: cHtml)
                }

                var refs: String? = nil
                if let cRefs = sqlite3_column_text(stmt, 7) {
                    refs = String(cString: cRefs)
                }

                list.append(NTBTCommentary(
                    canonicalId: cid,
                    bookNumber: bnum,
                    chapter: ch,
                    verse: v,
                    title: title,
                    subtitle: subtitle,
                    commentaryHtml: html,
                    referencesText: refs
                ))
            }
        }
        sqlite3_finalize(stmt)
        return list
    }

    public func fetchNTBTBookIntro(bookNumber: Int) -> NTBTBookIntro? {
        let activeDb = commentaryDb ?? db
        guard let dbToUse = activeDb else { return nil }
        let query = "SELECT book_number, book_code, book_name, intro_html FROM ntbt_book_intros WHERE book_number = ? LIMIT 1;"
        var stmt: OpaquePointer?
        var intro: NTBTBookIntro? = nil

        if sqlite3_prepare_v2(dbToUse, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(bookNumber))
            if sqlite3_step(stmt) == SQLITE_ROW {
                let bnum = Int(sqlite3_column_int(stmt, 0))
                let code = String(cString: sqlite3_column_text(stmt, 1))
                let name = String(cString: sqlite3_column_text(stmt, 2))
                let html = String(cString: sqlite3_column_text(stmt, 3))
                intro = NTBTBookIntro(bookNumber: bnum, bookCode: code, bookName: name, introHtml: html)
            }
        }
        sqlite3_finalize(stmt)
        return intro
    }
}
