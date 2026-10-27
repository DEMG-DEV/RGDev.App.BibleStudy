import SwiftUI

public struct ChapterPickerPopover: View {
    @ObservedObject var appState: AppState
    let book: BibleBook
    @Binding var isPresented: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 38, maximum: 44), spacing: 6)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.name)
                        .font(.headline)
                    Text("\(book.totalChapters) capítulos • \(book.category)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(1...book.totalChapters, id: \.self) { chapter in
                        let isSelected = (book.id == appState.selectedBook.id && chapter == appState.selectedChapter)

                        Button {
                            appState.jumpTo(book: book, chapter: chapter)
                            isPresented = false
                        } label: {
                            Text("\(chapter)")
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                .frame(width: 38, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                )
                                .foregroundColor(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 240)
        }
        .padding(14)
        .frame(width: 280)
    }
}
