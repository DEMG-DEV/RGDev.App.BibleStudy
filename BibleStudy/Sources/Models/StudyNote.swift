import Foundation

public struct StudyNote: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var canonicalVerseId: Int
    public var verseReference: String
    public var versionUsed: String
    public var topic: String
    public var summary: String
    public var content: String
    public var highlightColorHex: String
    public var appleNoteId: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        canonicalVerseId: Int,
        verseReference: String,
        versionUsed: String = "RVR1960",
        topic: String = "Estudio General",
        summary: String = "",
        content: String = "",
        highlightColorHex: String = "#FFD60A",
        appleNoteId: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.canonicalVerseId = canonicalVerseId
        self.verseReference = verseReference
        self.versionUsed = versionUsed
        self.topic = topic
        self.summary = summary
        self.content = content
        self.highlightColorHex = highlightColorHex
        self.appleNoteId = appleNoteId
    }

    /// Formato de hora exacta (Ej: "17:45")
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }

    /// Título de agrupación de fecha (Ej: "Hoy", "Ayer", etc.)
    public var dayGroupTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            return "Hoy"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Ayer"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.dateFormat = "EEEE, d 'de' MMMM yyyy"
            return formatter.string(from: createdAt).capitalized
        }
    }
}
