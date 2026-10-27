import Foundation

public final class AppleNotesBridge: @unchecked Sendable {
    public static let shared = AppleNotesBridge()

    private init() {}

    /// Sincroniza una nota con Notas de Apple y devuelve el identificador oficial de Apple Notes
    public func syncNote(note: StudyNote, folderName: String = "Estudio Bíblico", completion: (@MainActor @Sendable (String?) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let noteId = self.executeSyncScript(note: note, folderName: folderName)
            DispatchQueue.main.async {
                completion?(noteId)
            }
        }
    }

    /// Elimina la nota en Notas de Apple
    public func deleteNote(noteId: UUID, appleNoteId: String?, folderName: String = "Estudio Bíblico") {
        DispatchQueue.global(qos: .utility).async {
            let escapedFolder = self.escapeAppleScriptString(folderName)
            let noteRefTag = "[ref:\(noteId.uuidString)]"
            let escapedTag = self.escapeAppleScriptString(noteRefTag)

            var script = "tell application \"Notes\"\n"
            if let aId = appleNoteId, !aId.isEmpty {
                let escapedId = self.escapeAppleScriptString(aId)
                script += """
                    if (exists note id "\(escapedId)") then
                        delete note id "\(escapedId)"
                        return
                    end if
                """
            }

            script += """
                if (exists folder "\(escapedFolder)") then
                    tell folder "\(escapedFolder)"
                        set matchingNotes to (every note whose body contains "\(escapedTag)")
                        repeat with n in matchingNotes
                            delete n
                        end repeat
                    end tell
                end if
            end tell
            """

            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    private func executeSyncScript(note: StudyNote, folderName: String) -> String? {
        let noteRefTag = "[ref:\(note.id.uuidString)]"
        let noteTitle = "\(note.verseReference) — \(note.topic)"
        let formattedDate = "\(note.dayGroupTitle) a las \(note.timeString)"

        // Build HTML body for Apple Notes
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

        // Persistent tracking ref tag
        html += "<p style=\"font-size: 9px; color: #ced4da; margin-top: 18px;\">Generado automáticamente por BibleStudy \(noteRefTag)</p>"
        html += "</div>"

        let escapedFolderName = escapeAppleScriptString(folderName)
        let escapedTitle = escapeAppleScriptString(noteTitle)
        let escapedHtml = escapeAppleScriptString(html)
        let escapedRefTag = escapeAppleScriptString(noteRefTag)
        let escapedVerse = escapeAppleScriptString(note.verseReference)

        var script = "tell application \"Notes\"\n"
        script += "    set targetFolderName to \"\(escapedFolderName)\"\n"
        script += "    if not (exists folder targetFolderName) then\n"
        script += "        make new folder with properties {name:targetFolderName}\n"
        script += "    end if\n\n"

        // 1. If we have the exact appleNoteId, update directly
        if let aId = note.appleNoteId, !aId.isEmpty {
            let escapedId = escapeAppleScriptString(aId)
            script += """
                if (exists note id "\(escapedId)") then
                    set currentNote to note id "\(escapedId)"
                    set body of currentNote to "\(escapedHtml)"
                    return id of currentNote as text
                end if

            """
        }

        // 2. Fallback search inside folder by refTag, or by title containing the verse
        script += """
            tell folder targetFolderName
                set existingNotes to (every note whose body contains "\(escapedRefTag)")
                if (count of existingNotes) = 0 then
                    set existingNotes to (every note whose name contains "\(escapedVerse)")
                end if

                if (count of existingNotes) > 0 then
                    set currentNote to first item of existingNotes
                    set body of currentNote to "\(escapedHtml)"
                    return id of currentNote as text
                else
                    set newNote to make new note with properties {name:"\(escapedTitle)", body:"\(escapedHtml)"}
                    return id of newNote as text
                end if
            end tell
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let resultDesc = appleScript.executeAndReturnError(&error)
            if let err = error {
                print("⚠️ AppleNotesBridge Error: \(err)")
                return nil
            }
            return resultDesc.stringValue
        }
        return nil
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
