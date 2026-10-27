import SwiftUI

@main
struct BibleStudyApp: App {
    init() {
        print("✅ Bundle ID initialized:", Bundle.main.bundleIdentifier ?? "nil")
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 850, minHeight: 550)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            InspectorCommands()
        }
    }
}
