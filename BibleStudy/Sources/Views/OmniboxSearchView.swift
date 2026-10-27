import SwiftUI

public struct OmniboxSearchView: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    @FocusState private var isFieldFocused: Bool

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 15))

                TextField("Buscar cita (Ej: 'Jn 3:16', 'Sal 23') o palabra...", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isFieldFocused)
                    .onSubmit {
                        appState.executeSearch()
                    }

                if !appState.searchQuery.isEmpty {
                    Button {
                        appState.searchQuery = ""
                        appState.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button("Cerrar") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Results List
            if appState.searchResults.isEmpty {
                if appState.searchQuery.isEmpty {
                    hintView
                } else {
                    noResultsView
                }
            } else {
                resultsList
            }
        }
        .frame(width: 520, height: 400)
        .onAppear {
            isFieldFocused = true
        }
    }

    private var hintView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Buscador Inteligente y Navegador Rápido")
                .font(.system(size: 13, weight: .bold))
            Text("• Escribe una cita directa como **Jn 3:16**, **Sal 23** o **1Co 13** para saltar instantáneamente.\n• O escribe palabras clave como **amor de Dios**, **fe**, **gracia** para buscar en todo el texto bíblico.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No se encontraron versículos para:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text("\"\(appState.searchQuery)\"")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(appState.searchResults) { res in
                    Button {
                        if let book = appState.allBooks.first(where: { $0.name == res.bookName }) {
                            appState.jumpTo(book: book, chapter: res.chapter, verse: res.verse)
                            isPresented = false
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("\(res.bookName) \(res.chapter):\(res.verse)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Text(res.versionId)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            // Clean snippet without HTML tags
                            Text(res.snippet.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: ""))
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }
}
