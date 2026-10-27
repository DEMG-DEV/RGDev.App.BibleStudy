import Foundation

public struct BibleVerse: Identifiable, Hashable, Codable {
    public var id: String { "\(versionId)_\(canonicalId)" }
    public let canonicalId: Int
    public let versionId: String
    public let bookNumber: Int
    public let chapter: Int
    public let verse: Int
    public let text: String
    public let heading: String?

    public init(
        canonicalId: Int,
        versionId: String,
        bookNumber: Int,
        chapter: Int,
        verse: Int,
        text: String,
        heading: String? = nil
    ) {
        self.canonicalId = canonicalId
        self.versionId = versionId
        self.bookNumber = bookNumber
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.heading = heading
    }
}

public struct SearchResult: Identifiable, Hashable {
    public var id: String { "\(versionId)_\(canonicalId)" }
    public let canonicalId: Int
    public let versionId: String
    public let bookName: String
    public let chapter: Int
    public let verse: Int
    public let snippet: String
    public let fullText: String
}
