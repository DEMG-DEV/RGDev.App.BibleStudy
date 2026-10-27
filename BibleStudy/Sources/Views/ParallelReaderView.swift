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
        let isHighlighted = (appState.highlightedVerseNumber == vnum)
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
                    verseCell(versionId: versionId, vnum: vnum, isHighlighted: isHighlighted)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHighlighted ? Color.accentColor.opacity(0.12) : (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHighlighted ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .onHover { hovering in
            hoveredVerse = hovering ? vnum : nil
        }
        .onTapGesture {
            appState.highlightedVerseNumber = vnum
        }
    }

    @ViewBuilder
    private func verseCell(versionId: String, vnum: Int, isHighlighted: Bool) -> some View {
        if let verse = appState.currentParallelVerses[vnum]?[versionId] {
            HStack(alignment: .top, spacing: 6) {
                // Verse number badge
                Text("\(vnum)")
                    .font(.system(size: max(9, appState.fontSize - 6), weight: .bold, design: .rounded))
                    .foregroundColor(isHighlighted ? .white : .secondary)
                    .frame(minWidth: 20, alignment: .center)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isHighlighted ? Color.accentColor : Color.clear)
                    )

                // Verse Text with Red Letter Words
                RedLetterText(
                    rawText: verse.text,
                    isRedLetterEnabled: appState.isRedLetterEnabled,
                    fontSize: appState.fontSize,
                    fontDesign: appState.fontDesign
                )

                Spacer(minLength: 0)

                // Quick Note Action button on selection
                if isHighlighted {
                    Button {
                        appState.createNoteForCurrentSelection(verseNumber: vnum)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Crear nota de estudio para este versículo")
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
        default: return id
        }
    }
}
