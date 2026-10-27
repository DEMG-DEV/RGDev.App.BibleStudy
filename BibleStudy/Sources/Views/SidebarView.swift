import SwiftUI

public enum TestamentFilter: String, CaseIterable, Identifiable {
    case all = "Todos"
    case oldTestament = "A.T. (39)"
    case newTestament = "N.T. (27)"

    public var id: String { rawValue }
}

public struct SidebarView: View {
    @ObservedObject var appState: AppState
    @State private var filter: TestamentFilter = .all
    @State private var searchText: String = ""
    @State private var activePopoverBook: BibleBook? = nil

    private var filteredBooks: [BibleBook] {
        var list = appState.allBooks
        switch filter {
        case .all: break
        case .oldTestament:
            list = list.filter { $0.testament == .oldTestament }
        case .newTestament:
            list = list.filter { $0.testament == .newTestament }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            list = list.filter {
                $0.name.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(q) ||
                $0.abbreviation.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(q) ||
                $0.category.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(q)
            }
        }
        return list
    }

    private var groupedBooks: [(category: String, books: [BibleBook])] {
        let books = filteredBooks
        let categories = ["Pentateuco", "Históricos", "Poéticos y Sabiduría", "Profetas Mayores", "Profetas Menores",
                          "Evangelios", "Historia", "Epístolas Paulinas", "Epístolas Generales", "Profecía"]

        var result: [(category: String, books: [BibleBook])] = []
        for cat in categories {
            let inCat = books.filter { $0.category == cat }
            if !inCat.isEmpty {
                result.append((category: cat, books: inCat))
            }
        }

        let covered = Set(result.flatMap { $0.books.map { $0.id } })
        let remaining = books.filter { !covered.contains($0.id) }
        if !remaining.isEmpty {
            result.append((category: "Otros", books: remaining))
        }

        return result
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Filter Header (Apple HIG Segmented Control)
            Picker("Testamento", selection: $filter) {
                ForEach(TestamentFilter.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Search Filter
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("Filtrar libro (Ej: Jn, Sal, Ex)", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            Divider()

            // Canonical Physical Bible List
            List {
                ForEach(groupedBooks, id: \.category) { group in
                    Section(header: Text(group.category).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)) {
                        ForEach(group.books) { book in
                            bookRow(book)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 220, idealWidth: 260)
    }

    @ViewBuilder
    private func bookRow(_ book: BibleBook) -> some View {
        let isSelected = (book.id == appState.selectedBook.id)

        HStack {
            // Main Book Selection Button
            Button {
                if appState.selectedBook.id != book.id {
                    appState.jumpTo(book: book, chapter: 1)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "book.fill" : "book")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.system(size: 12))

                    Text(book.name)
                        .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .accentColor : .primary)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Thumb index popover button
            Button {
                activePopoverBook = book
            } label: {
                HStack(spacing: 2) {
                    if isSelected {
                        Text("Cap. \(appState.selectedChapter)")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    } else {
                        Text("\(book.totalChapters)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: Binding(
                get: { activePopoverBook?.id == book.id },
                set: { if !$0 { activePopoverBook = nil } }
            ), arrowEdge: .trailing) {
                ChapterPickerPopover(appState: appState, book: book, isPresented: Binding(
                    get: { activePopoverBook?.id == book.id },
                    set: { if !$0 { activePopoverBook = nil } }
                ))
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
    }
}
