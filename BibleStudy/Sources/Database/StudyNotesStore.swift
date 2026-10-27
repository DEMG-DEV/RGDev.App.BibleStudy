import Foundation
import Combine

@MainActor
public final class StudyNotesStore: ObservableObject {
    public static let shared = StudyNotesStore()

    @Published public private(set) var notes: [StudyNote] = []
    @Published public var isAutoSyncWithAppleNotesEnabled: Bool = true

    private var fileURL: URL?

    private init() {
        self.fileURL = determineStorageURL()
        loadNotes()
        if notes.isEmpty {
            createInitialSampleNotes()
        }
    }

    private func determineStorageURL() -> URL {
        let fileManager = FileManager.default
        var candidateDirs: [URL] = []

        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            candidateDirs.append(appSupport.appendingPathComponent("RGDev.App.BibleStudy", isDirectory: true))
        }

        if let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            candidateDirs.append(docs.appendingPathComponent("BibleStudyNotes", isDirectory: true))
        }

        let localUserData = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("UserData", isDirectory: true)
        candidateDirs.append(localUserData)

        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("RGDev.App.BibleStudy", isDirectory: true)
        candidateDirs.append(tempDir)

        for dir in candidateDirs {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
                let testFile = dir.appendingPathComponent(".write_test")
                try "ok".write(to: testFile, atomically: true, encoding: .utf8)
                try fileManager.removeItem(at: testFile)
                print("✅ StudyNotesStore: Using storage directory: \(dir.path)")
                return dir.appendingPathComponent("study_notes.json")
            } catch {
                continue
            }
        }

        let fallback = fileManager.temporaryDirectory.appendingPathComponent("study_notes.json")
        return fallback
    }

    private func loadNotes() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loaded = try decoder.decode([StudyNote].self, from: data)
            self.notes = loaded.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("⚠️ StudyNotesStore: Failed to load notes: \(error)")
        }
    }

    private func saveToDisk() {
        guard let url = fileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notes)
            try data.write(to: url, options: .atomic)
        } catch {
            print("⚠️ StudyNotesStore: Failed to save notes: \(error)")
        }
    }

    public func save(note: StudyNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            notes[index].updatedAt = Date()
        } else {
            notes.insert(note, at: 0)
        }
        notes.sort(by: { $0.createdAt > $1.createdAt })
        saveToDisk()

        // Sincronización automática silenciosa con Notas de Apple
        if isAutoSyncWithAppleNotesEnabled {
            AppleNotesBridge.shared.syncNote(note: note)
        }
    }

    public func delete(id: UUID) {
        notes.removeAll(where: { $0.id == id })
        saveToDisk()

        if isAutoSyncWithAppleNotesEnabled {
            AppleNotesBridge.shared.deleteNote(noteId: id)
        }
    }

    public func syncAllNotesToAppleNotes(completion: (() -> Void)? = nil) {
        for note in notes {
            AppleNotesBridge.shared.syncNote(note: note)
        }
        completion?()
    }

    public func notesGroupedByDay() -> [(dayTitle: String, notes: [StudyNote])] {
        let grouped = Dictionary(grouping: notes) { note -> String in
            return note.dayGroupTitle
        }

        var result: [(dayTitle: String, notes: [StudyNote])] = []
        let uniqueTitles = notes.map { $0.dayGroupTitle }.reduce(into: [String]()) { all, title in
            if !all.contains(title) { all.append(title) }
        }

        for title in uniqueTitles {
            if let groupNotes = grouped[title] {
                result.append((dayTitle: title, notes: groupNotes.sorted(by: { $0.createdAt > $1.createdAt })))
            }
        }
        return result
    }

    public func notesForChapter(bookNumber: Int, chapter: Int) -> [StudyNote] {
        let minId = (bookNumber * 1_000_000) + (chapter * 1_000)
        let maxId = minId + 999
        return notes.filter { $0.canonicalVerseId >= minId && $0.canonicalVerseId <= maxId }
    }

    public func allTopics() -> [String] {
        var set = Set<String>()
        for note in notes {
            let t = note.topic.trimmingCharacters(in: .whitespaces)
            if !t.isEmpty { set.insert(t) }
        }
        return Array(set).sorted()
    }

    private func createInitialSampleNotes() {
        let sample = StudyNote(
            canonicalVerseId: 43003016, // Juan 3:16
            verseReference: "Juan 3:16",
            versionUsed: "RVR1960 / NTV",
            topic: "Salvación y Gracia",
            summary: "El amor incondicional del Padre expresado en la entrega de su único Hijo para vida eterna.",
            content: "Análisis exegético del término 'ágape' en Juan 3:16. La iniciativa es 100% divina. En contraste entre RVR1960 ('unigénito') y NTV ('único Hijo'), ambas captan la singularidad del Mesías.",
            highlightColorHex: "#30D158"
        )
        self.notes = [sample]
        saveToDisk()
    }
}
