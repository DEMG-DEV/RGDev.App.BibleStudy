import Foundation

public enum Testament: String, Codable, CaseIterable {
    case oldTestament = "AT"
    case newTestament = "NT"

    public var title: String {
        switch self {
        case .oldTestament: return "Antiguo Testamento"
        case .newTestament: return "Nuevo Testamento"
        }
    }
}

public struct BibleBook: Identifiable, Hashable, Codable {
    public let id: Int // 1..66
    public let testament: Testament
    public let category: String
    public let name: String
    public let usfm: String
    public let abbreviation: String
    public let totalChapters: Int

    public init(
        id: Int,
        testament: Testament,
        category: String,
        name: String,
        usfm: String,
        abbreviation: String,
        totalChapters: Int
    ) {
        self.id = id
        self.testament = testament
        self.category = category
        self.name = name
        self.usfm = usfm
        self.abbreviation = abbreviation
        self.totalChapters = totalChapters
    }
}
