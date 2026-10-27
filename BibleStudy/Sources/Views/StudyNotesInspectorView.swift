import SwiftUI

public struct StudyNotesInspectorView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var notesStore = StudyNotesStore.shared

    @State private var filterCurrentChapterOnly: Bool = false
    @State private var selectedTopicFilter: String = "Todos"
    @State private var editingNote: StudyNote? = nil
    @State private var isSyncingAll: Bool = false

    private var displayedDayGroups: [(dayTitle: String, notes: [StudyNote])] {
        let baseGroups = notesStore.notesGroupedByDay()

        var filtered: [(dayTitle: String, notes: [StudyNote])] = []
        for group in baseGroups {
            var groupNotes = group.notes

            if filterCurrentChapterOnly {
                let minCid = (appState.selectedBook.id * 1_000_000) + (appState.selectedChapter * 1_000)
                let maxCid = minCid + 999
                groupNotes = groupNotes.filter { $0.canonicalVerseId >= minCid && $0.canonicalVerseId <= maxCid }
            }

            if selectedTopicFilter != "Todos" {
                groupNotes = groupNotes.filter { $0.topic == selectedTopicFilter }
            }

            if !groupNotes.isEmpty {
                filtered.append((dayTitle: group.dayTitle, notes: groupNotes))
            }
        }
        return filtered
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Inspector Header
            inspectorHeader

            Divider()

            // Filters & Apple Notes Sync bar
            filterBar

            Divider()

            // Chronological List
            if displayedDayGroups.isEmpty {
                emptyNotesView
            } else {
                notesListView
            }

            Divider()

            // Bottom Apple Notes sync status
            appleNotesFooter
        }
        .frame(minWidth: 280, idealWidth: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $editingNote) { note in
            NoteEditorSheet(note: note) { savedNote in
                notesStore.save(note: savedNote)
                editingNote = nil
            } onCancel: {
                editingNote = nil
            } onDelete: { noteId in
                notesStore.delete(id: noteId)
                editingNote = nil
            }
        }
        .onChange(of: appState.selectedNoteForEditing) { _, note in
            if let n = note {
                editingNote = n
                appState.selectedNoteForEditing = nil
            }
        }
    }

    private var inspectorHeader: some View {
        HStack {
            Image(systemName: "note.text")
                .foregroundColor(.accentColor)
                .font(.system(size: 14))

            Text("Notas de Estudio")
                .font(.system(size: 13, weight: .bold))

            Spacer()

            // Add Note Button
            Button {
                appState.createNoteForCurrentSelection()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 15))
            }
            .buttonStyle(.plain)
            .help("Nueva nota de estudio")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var filterBar: some View {
        VStack(spacing: 6) {
            // Chapter toggle
            Toggle(isOn: $filterCurrentChapterOnly) {
                Text("Solo este capítulo (\(appState.selectedBook.abbreviation) \(appState.selectedChapter))")
                    .font(.system(size: 11))
            }
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Topic dropdown
            HStack {
                Text("Tema:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedTopicFilter) {
                    Text("Todos los temas").tag("Todos")
                    ForEach(notesStore.allTopics(), id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(size: 11))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var notesListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(displayedDayGroups, id: \.dayTitle) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Day Group Header (Cronología)
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(group.dayTitle)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)

                        // Notes in this day
                        ForEach(group.notes) { note in
                            noteCard(note)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func noteCard(_ note: StudyNote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Verse Reference & Time
            HStack {
                Button {
                    jumpToNoteVerse(note)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.accentColor)
                        Text(note.verseReference)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Exact creation time
                Text(note.timeString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Topic Badge & Apple Notes Sync Badge
            HStack(spacing: 6) {
                if !note.topic.isEmpty {
                    Text(note.topic)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(4)
                }

                Spacer()

                // Apple Notes indicator
                if notesStore.isAutoSyncWithAppleNotesEnabled {
                    HStack(spacing: 2) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 9))
                        Text("Notas")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                    .help("Sincronizada con la carpeta 'Estudio Bíblico' en Notas de Apple")
                }
            }

            // Executive Summary Callout
            if !note.summary.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    Text(note.summary)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                .padding(.vertical, 2)
            }

            // Note Content Snippet
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            editingNote = note
        }
    }

    private var appleNotesFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "applelogo")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text("Notas de Apple (iCloud)")
                    .font(.system(size: 10, weight: .semibold))
                Text("Carpeta: Estudio Bíblico")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $notesStore.isAutoSyncWithAppleNotesEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .help("Activar o desactivar guardado automático silencioso en Notas de Apple")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var emptyNotesView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "square.and.pencil")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text("No hay notas aún")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Haz clic en cualquier versículo o pulsa el botón '+' para crear tu primera nota de estudio.")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
        }
    }

    private func jumpToNoteVerse(_ note: StudyNote) {
        let cid = note.canonicalVerseId
        let bnum = cid / 1_000_000
        let ch = (cid % 1_000_000) / 1_000
        let v = cid % 1_000

        if let book = appState.allBooks.first(where: { $0.id == bnum }) {
            appState.jumpTo(book: book, chapter: ch, verse: v)
        }
    }
}

// Full Editor Sheet
public struct NoteEditorSheet: View {
    @State private var note: StudyNote
    let onSave: (StudyNote) -> Void
    let onCancel: () -> Void
    let onDelete: (UUID) -> Void

    public init(
        note: StudyNote,
        onSave: @escaping (StudyNote) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: @escaping (UUID) -> Void
    ) {
        _note = State(initialValue: note)
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Sheet Header
            HStack {
                Text(note.verseReference.isEmpty ? "Nueva Nota de Estudio" : "Nota: \(note.verseReference)")
                    .font(.headline)
                Spacer()
                Text("\(note.dayGroupTitle) a las \(note.timeString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Form Fields
            VStack(alignment: .leading, spacing: 12) {
                // Topic Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tema / Doctrina:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextField("Ej: Salvación, Gracia, Justificación, Promesa...", text: $note.topic)
                        .textFieldStyle(.roundedBorder)
                }

                // Executive Summary Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resumen Ejecutivo (Idea Clave):")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextField("1 o 2 líneas resumiendo el principio o revelación principal", text: $note.summary)
                        .textFieldStyle(.roundedBorder)
                }

                // Detailed Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Desarrollo y Apuntes de Estudio:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextEditor(text: $note.content)
                        .font(.system(size: 13))
                        .frame(minHeight: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }

            // Sync notification badge
            HStack(spacing: 4) {
                Image(systemName: "applelogo")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("Se guardará automáticamente en la carpeta **Estudio Bíblico** de Notas de Apple.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider()

            // Footer Actions
            HStack {
                Button(role: .destructive) {
                    onDelete(note.id)
                } label: {
                    Text("Eliminar")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Cancelar") {
                    onCancel()
                }
                .buttonStyle(.plain)

                Button("Guardar Nota") {
                    onSave(note)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 480, height: 440)
    }
}
