import SwiftUI

public struct ParallelReaderView: View {
    @ObservedObject var appState: AppState
    @State private var hoveredVerse: Int? = nil

    private var activeVersionsList: [String] {
        appState.activeVersions
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Chapter Header
                    chapterHeaderView

                    Divider()
                        .padding(.horizontal)

                    // Sticky Column Headers (Translations)
                    versionColumnsHeader
                        .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Synchronized Row-by-Row Parallel Verses
                    LazyVStack(spacing: 12) {
                        ForEach(appState.sortedVerseNumbers, id: \.self) { vnum in
                            parallelVerseRow(vnum: vnum)
                                .id("verse_\(vnum)")
                        }
                    }
                    .padding(.horizontal)

                    // Bottom Continuous Page Turners (Like physical Bible)
                    chapterNavigationFooter
                }
                .padding(.vertical, 16)
                .padding(.bottom, appState.selectedVerseNumbers.isEmpty ? 0 : 60)
            }
            .onChange(of: appState.highlightedVerseNumber) { _, targetVerse in
                if let v = targetVerse {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("verse_\(v)", anchor: .center)
                    }
                }
            }
            .onAppear {
                if let v = appState.highlightedVerseNumber {
                    proxy.scrollTo("verse_\(v)", anchor: .center)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .overlay(alignment: .bottom) {
            if !appState.selectedVerseNumbers.isEmpty {
                multiVerseActionBar
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.selectedVerseNumbers)
    }

    private var chapterHeaderView: some View {
        VStack(spacing: 4) {
            Text(appState.selectedBook.name)
                .font(.system(size: 26, weight: .bold, design: appState.fontDesign == .serif ? .serif : .default))

            Text("Capítulo \(appState.selectedChapter)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            // Active versions badges
            HStack(spacing: 8) {
                ForEach(activeVersionsList, id: \.self) { vid in
                    Text(versionDisplayName(vid))
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }
            .padding(.top, 4)
        }
    }

    private var versionColumnsHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            ForEach(activeVersionsList, id: \.self) { versionId in
                HStack {
                    Text(versionDisplayName(versionId))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(versionId)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func parallelVerseRow(vnum: Int) -> some View {
        let isSelected = appState.selectedVerseNumbers.contains(vnum) || (appState.highlightedVerseNumber == vnum && appState.selectedVerseNumbers.isEmpty)
        let isHovered = (hoveredVerse == vnum)

        // Check if any version has a pericope heading for this verse
        let headingText: String? = activeVersionsList.compactMap { vid in
            appState.currentParallelVerses[vnum]?[vid]?.heading
        }.first

        VStack(alignment: .leading, spacing: 6) {
            // Pericope heading banner if present
            if let heading = headingText, !heading.isEmpty {
                HStack {
                    Text(heading)
                        .font(.system(size: appState.fontSize, weight: .bold, design: appState.fontDesign == .serif ? .serif : .default))
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 2)
            }

            // Synchronized Parallel Columns for this exact verse
            HStack(alignment: .top, spacing: 16) {
                ForEach(activeVersionsList, id: \.self) { versionId in
                    verseCell(versionId: versionId, vnum: vnum, isSelected: isSelected)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredVerse = hovering ? vnum : nil
        }
        .onTapGesture {
            let flags = NSEvent.modifierFlags
            let isShift = flags.contains(.shift)
            let isCommand = flags.contains(.command)
            appState.handleVerseClick(vnum, isShift: isShift, isCommand: isCommand)
        }
        .contextMenu {
            Button {
                appState.showCommentary(for: vnum)
            } label: {
                Label("Ver Comentarios NTBT (versículo \(vnum))", systemImage: "text.book.closed.fill")
            }

            Button {
                appState.createNoteForCurrentSelection(verseNumber: isSelected ? nil : vnum)
            } label: {
                Label(isSelected && appState.selectedVerseNumbers.count > 1 ? "Crear nota para versículos seleccionados" : "Crear nota para versículo \(vnum)", systemImage: "square.and.pencil")
            }

            Button {
                if !isSelected {
                    appState.selectSingleVerse(vnum)
                }
                copySelectedVersesToClipboard()
            } label: {
                Label("Copiar versículo(s)", systemImage: "doc.on.doc")
            }

            if !appState.selectedVerseNumbers.isEmpty {
                Divider()
                Button {
                    appState.clearVerseSelection()
                } label: {
                    Label("Deseleccionar todo", systemImage: "xmark.circle")
                }
            }
        }
    }

    @ViewBuilder
    private func verseCell(versionId: String, vnum: Int, isSelected: Bool) -> some View {
        if let verse = appState.currentParallelVerses[vnum]?[versionId] {
            HStack(alignment: .top, spacing: 6) {
                // Verse selection indicator & number badge
                Button {
                    appState.toggleVerse(vnum)
                } label: {
                    HStack(spacing: 3) {
                        if isSelected || appState.selectedVerseNumbers.count > 1 || hoveredVerse == vnum {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.6))
                        }
                        Text("\(vnum)")
                            .font(.system(size: max(9, appState.fontSize - 6), weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .secondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .help("Seleccionar versículo (Shift+Clic para rango, ⌘+Clic para varios)")

                // Verse Text with Red Letter Words
                RedLetterText(
                    rawText: verse.text,
                    isRedLetterEnabled: appState.isRedLetterEnabled,
                    fontSize: appState.fontSize,
                    fontDesign: appState.fontDesign
                )

                Spacer(minLength: 0)

                // Quick Note Action button on selection (only on rightmost column)
                if isSelected && versionId == activeVersionsList.last {
                    Button {
                        appState.createNoteForCurrentSelection(verseNumber: appState.selectedVerseNumbers.count > 1 ? nil : vnum)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Crear nota de estudio para los versículos seleccionados")
                }
            }
        } else {
            // Verse merged or omitted in dynamic equivalence
            HStack(alignment: .top, spacing: 6) {
                Text("\(vnum)")
                    .font(.system(size: max(9, appState.fontSize - 6), weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("— (Incluido en versículo contiguo)")
                    .font(.system(size: appState.fontSize - 3))
                    .foregroundColor(.secondary.opacity(0.6))
                    .italic()
            }
        }
    }

    private var multiVerseActionBar: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 15))

            VStack(alignment: .leading, spacing: 1) {
                Text(appState.selectedVersesReference)
                    .font(.system(size: 13, weight: .bold))
                Text("\(appState.selectedVerseNumbers.count) versículo\(appState.selectedVerseNumbers.count == 1 ? "" : "s") seleccionado\(appState.selectedVerseNumbers.count == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 18)

            // Copy button
            Button {
                copySelectedVersesToClipboard()
            } label: {
                Label("Copiar", systemImage: "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Commentary button
            Button {
                appState.showCommentary()
            } label: {
                Label("Comentarios", systemImage: "text.book.closed.fill")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Add Note button
            Button {
                appState.createNoteForCurrentSelection()
            } label: {
                Label("Crear Nota", systemImage: "square.and.pencil")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Divider()
                .frame(height: 18)

            // Deselect button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.clearVerseSelection()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Deseleccionar versículos")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 520)
    }

    private func copySelectedVersesToClipboard() {
        let citation = appState.selectedVersesReference
        let version = appState.activeVersions.first ?? "RVR1960"
        let versesText = appState.selectedVersesPlainText(versionId: version)
        let fullString = "«\(versesText)»\n— \(citation) (\(version))"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fullString, forType: .string)
    }

    private var chapterNavigationFooter: some View {
        HStack {
            // Previous Chapter
            if appState.selectedChapter > 1 {
                Button {
                    appState.jumpTo(book: appState.selectedBook, chapter: appState.selectedChapter - 1)
                } label: {
                    Label("Capítulo \(appState.selectedChapter - 1)", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            // Next Chapter
            if appState.selectedChapter < appState.selectedBook.totalChapters {
                Button {
                    appState.jumpTo(book: appState.selectedBook, chapter: appState.selectedChapter + 1)
                } label: {
                    HStack {
                        Text("Capítulo \(appState.selectedChapter + 1)")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private func versionDisplayName(_ id: String) -> String {
        switch id {
        case "RVR1960": return "Reina-Valera 1960"
        case "NTV": return "Nueva Traducción Viviente"
        case "TLA": return "Traducción en Lenguaje Actual"
        case "NVI": return "Nueva Versión Internacional"
        case "NTBT": return "Nueva Traducción BibliaTodo"
        default: return id
        }
    }
}
