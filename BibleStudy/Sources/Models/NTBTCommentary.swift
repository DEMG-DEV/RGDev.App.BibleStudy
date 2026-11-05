import Foundation

public struct NTBTCommentary: Identifiable, Hashable, Sendable {
    public var id: Int { canonicalId }
    public let canonicalId: Int
    public let bookNumber: Int
    public let chapter: Int
    public let verse: Int
    public let title: String?
    public let subtitle: String?
    public let commentaryHtml: String
    public let referencesText: String?

    public init(
        canonicalId: Int,
        bookNumber: Int,
        chapter: Int,
        verse: Int,
        title: String?,
        subtitle: String?,
        commentaryHtml: String,
        referencesText: String?
    ) {
        self.canonicalId = canonicalId
        self.bookNumber = bookNumber
        self.chapter = chapter
        self.verse = verse
        self.title = title
        self.subtitle = subtitle
        self.commentaryHtml = commentaryHtml
        self.referencesText = referencesText
    }
}

public struct NTBTBookIntro: Identifiable, Hashable, Sendable {
    public var id: Int { bookNumber }
    public let bookNumber: Int
    public let bookCode: String
    public let bookName: String
    public let introHtml: String

    public init(bookNumber: Int, bookCode: String, bookName: String, introHtml: String) {
        self.bookNumber = bookNumber
        self.bookCode = bookCode
        self.bookName = bookName
        self.introHtml = introHtml
    }
}
