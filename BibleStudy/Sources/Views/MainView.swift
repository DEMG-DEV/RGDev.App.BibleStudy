import SwiftUI

public struct MainView: View {
    @StateObject private var appState = AppState()
    @State private var isSearchPresented: Bool = false
    @State private var isTypographyPopoverPresented: Bool = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 320)
        } detail: {
            ParallelReaderView(appState: appState)
                .inspector(isPresented: $appState.isNotesInspectorPresented) {
                    UnifiedInspectorView(appState: appState)
                        .inspectorColumnWidth(min: 280, ideal: 340, max: 420)
                }
        }
        .preferredColorScheme(appState.currentTheme.colorScheme)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $isSearchPresented) {
            OmniboxSearchView(appState: appState, isPresented: $isSearchPresented)
        }
        // Keyboard Shortcuts
        .background(
            Button("") {
                isSearchPresented.toggle()
            }
            .keyboardShortcut("k", modifiers: [.command])
            .opacity(0)
        )
        .background(
            Button("") {
                if appState.isNotesInspectorPresented && appState.activeInspectorTab == .notes {
                    appState.isNotesInspectorPresented = false
                } else {
                    appState.activeInspectorTab = .notes
                    appState.isNotesInspectorPresented = true
                }
            }
            .keyboardShortcut("n", modifiers: [.option, .command])
            .opacity(0)
        )
        .background(
            Button("") {
                if appState.isNotesInspectorPresented && appState.activeInspectorTab == .commentary {
                    appState.isNotesInspectorPresented = false
                } else {
                    appState.activeInspectorTab = .commentary
                    appState.isNotesInspectorPresented = true
                }
            }
            .keyboardShortcut("c", modifiers: [.option, .command])
            .opacity(0)
        )
        .background(
            Button("") {
                appState.toggleTheme()
            }
            .keyboardShortcut("t", modifiers: [.option, .command])
            .opacity(0)
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Translations Multi-Selector Pills
        ToolbarItemGroup(placement: .principal) {
            HStack(spacing: 4) {
                ForEach(appState.availableVersions, id: \.self) { vid in
                    let isActive = appState.activeVersions.contains(vid)
                    Button {
                        appState.toggleVersion(vid)
                    } label: {
                        Text(vid)
                            .font(.system(size: 11, weight: isActive ? .bold : .medium))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(isActive ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundColor(isActive ? .white : .primary)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Activar o desactivar traducción \(vid)")
                }
            }
            .padding(2)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .cornerRadius(7)
        }

        // Action controls
        ToolbarItemGroup(placement: .primaryAction) {
            // Red Letter (Palabras de Jesús) Toggle
            Button {
                appState.isRedLetterEnabled.toggle()
            } label: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(appState.isRedLetterEnabled ? Color(red: 0.85, green: 0.2, blue: 0.15) : Color.secondary.opacity(0.4))
                        .frame(width: 8, height: 8)
                    Text("Jesús")
                        .font(.system(size: 11, weight: appState.isRedLetterEnabled ? .semibold : .regular))
                }
            }
            .help(appState.isRedLetterEnabled ? "Palabras de Jesús resaltadas en rojo (activado)" : "Resaltado de palabras de Jesús desactivado")

            // Theme Toggle Button (Light / Dark / Auto)
            Menu {
                Picker("Tema", selection: $appState.currentTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.rawValue, systemImage: theme.iconName)
                            .tag(theme)
                    }
                }
            } label: {
                Image(systemName: appState.currentTheme.iconName)
            } primaryAction: {
                appState.toggleTheme()
            }
            .help("Tema de la app (Clic para alternar Claro / Oscuro, o desplegar para Automático • ⌥⌘T)")

            // Typography Popover
            Button {
                isTypographyPopoverPresented.toggle()
            } label: {
                Image(systemName: "textformat.size")
            }
            .help("Ajustar tamaño de letra y tipografía")
            .popover(isPresented: $isTypographyPopoverPresented) {
                typographyPopover
            }

            // Quick Search Button (⌘K)
            Button {
                isSearchPresented = true
            } label: {
                Label("Buscar (⌘K)", systemImage: "magnifyingglass")
            }
            .help("Buscar cita o palabra (⌘K)")

            // NTBT Commentary Inspector Toggle (⌥⌘C)
            Button {
                if appState.isNotesInspectorPresented && appState.activeInspectorTab == .commentary {
                    appState.isNotesInspectorPresented = false
                } else {
                    appState.activeInspectorTab = .commentary
                    appState.isNotesInspectorPresented = true
                }
            } label: {
                Label("Comentarios NTBT", systemImage: "text.book.closed.fill")
                    .foregroundColor(appState.isNotesInspectorPresented && appState.activeInspectorTab == .commentary ? .accentColor : .primary)
            }
            .help("Mostrar u ocultar comentarios de estudio NTBT (⌥⌘C)")

            // Notes Inspector Toggle (⌥⌘N)
            Button {
                if appState.isNotesInspectorPresented && appState.activeInspectorTab == .notes {
                    appState.isNotesInspectorPresented = false
                } else {
                    appState.activeInspectorTab = .notes
                    appState.isNotesInspectorPresented = true
                }
            } label: {
                Label("Mis Notas", systemImage: "note.text")
                    .foregroundColor(appState.isNotesInspectorPresented && appState.activeInspectorTab == .notes ? .accentColor : .primary)
            }
            .help("Mostrar u ocultar notas de estudio personales (⌥⌘N)")
        }
    }

    private var typographyPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tipografía de Lectura")
                .font(.headline)

            // Font Size Stepper
            HStack {
                Text("Tamaño:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    if appState.fontSize > 12 { appState.fontSize -= 1 }
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                Text("\(Int(appState.fontSize)) pt")
                    .font(.caption.monospacedDigit())
                    .frame(width: 36)
                Button {
                    if appState.fontSize < 28 { appState.fontSize += 1 }
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
            }

            Divider()

            // Font Family Choice
            VStack(alignment: .leading, spacing: 6) {
                Text("Diseño Tipográfico:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $appState.fontDesign) {
                    ForEach(ReaderFontDesign.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.radioGroup)
            }
        }
        .padding(14)
        .frame(width: 220)
    }
}
