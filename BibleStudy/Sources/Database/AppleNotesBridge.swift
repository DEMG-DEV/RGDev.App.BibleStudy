import Foundation

public final class AppleNotesBridge: @unchecked Sendable {
    public static let shared = AppleNotesBridge()

    private init() {}

    /// Sincroniza automáticamente una nota con la app Notas de Apple en la carpeta especificada
    public func syncNote(note: StudyNote, folderName: String = "Estudio Bíblico", completion: (@Sendable (Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let success = self.executeSyncScript(note: note, folderName: folderName)
            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }

    /// Elimina la nota correspondiente en Notas de Apple
    public func deleteNote(noteId: UUID, folderName: String = "Estudio Bíblico") {
        DispatchQueue.global(qos: .utility).async {
            let noteTag = "<!-- ID: \(noteId.uuidString) -->"
            let escapedFolder = self.escapeAppleScriptString(folderName)
            let scriptText = """
            tell application "Notes"
                if (exists folder "\(escapedFolder)") then
                    tell folder "\(escapedFolder)"
                        set matchingNotes to (every note whose body contains "\(noteTag)")
                        repeat with n in matchingNotes
                            delete n
                        end repeat
                    end tell
                end if
            end tell
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: scriptText) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    private func executeSyncScript(note: StudyNote, folderName: String) -> Bool {
        let noteIdTag = "<!-- ID: \(note.id.uuidString) -->"
        let noteTitle = "\(note.verseReference) — \(note.topic)"
        let formattedDate = "\(note.dayGroupTitle) a las \(note.timeString)"

        // Build elegant HTML body for Apple Notes
        var html = "<div>"
        html += "<h1>\(escapeHtml(noteTitle))</h1>"
        html += "<p style=\"color: #6c757d; font-size: 13px;\">📅 <i>\(escapeHtml(formattedDate))</i> • 📖 <b>\(escapeHtml(note.versionUsed))</b></p>"

        if !note.summary.isEmpty {
            html += "<p style=\"background-color: #f1f3f5; padding: 8px 12px; border-left: 4px solid #007aff; border-radius: 4px;\">"
            html += "💡 <b>Resumen:</b> \(escapeHtml(note.summary))"
            html += "</p>"
        }

        if !note.content.isEmpty {
            let formattedContent = escapeHtml(note.content).replacingOccurrences(of: "\n", with: "<br>")
            html += "<p style=\"font-size: 14px; line-height: 1.5;\">\(formattedContent)</p>"
        }

        html += "<p style=\"font-size: 10px; color: #adb5bd; margin-top: 16px;\">Generado automáticamente por BibleStudy \(noteIdTag)</p>"
        html += "</div>"

        let escapedFolderName = escapeAppleScriptString(folderName)
        let escapedTitle = escapeAppleScriptString(noteTitle)
        let escapedHtml = escapeAppleScriptString(html)
        let escapedTag = escapeAppleScriptString(noteIdTag)

        let script = """
        tell application "Notes"
            set targetFolderName to "\(escapedFolderName)"
            if not (exists folder targetFolderName) then
                make new folder with properties {name:targetFolderName}
            end if

            tell folder targetFolderName
                set existingNotes to (every note whose body contains "\(escapedTag)")
                if (count of existingNotes) > 0 then
                    set currentNote to first item of existingNotes
                    set body of currentNote to "\(escapedHtml)"
                else
                    make new note with properties {name:"\(escapedTitle)", body:"\(escapedHtml)"}
                end if
            end tell
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let err = error {
                print("⚠️ AppleNotesBridge Error: \(err)")
                return false
            }
            return true
        }
        return false
    }

    private func escapeAppleScriptString(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func escapeHtml(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
