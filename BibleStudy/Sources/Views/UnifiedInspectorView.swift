import SwiftUI

public struct UnifiedInspectorView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Inspector Top Tab Bar
            inspectorTopBar

            Divider()

            // Active Tab Content
            switch appState.activeInspectorTab {
            case .commentary:
                NTBTCommentaryInspectorView(appState: appState)
            case .notes:
                StudyNotesInspectorView(appState: appState)
            case .bookIntro:
                NTBTBookIntroInspectorView(appState: appState)
            }
        }
        .frame(minWidth: 280, idealWidth: 330)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var inspectorTopBar: some View {
        HStack(spacing: 6) {
            // Segmented Picker
            Picker("", selection: $appState.activeInspectorTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)

            Spacer()

            // Close Inspector button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.isNotesInspectorPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Ocultar panel lateral (⌥⌘N)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}
