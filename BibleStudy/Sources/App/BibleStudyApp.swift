import SwiftUI
import AppKit

@main
struct BibleStudyApp: App {
    init() {
        print("✅ Bundle ID initialized:", Bundle.main.bundleIdentifier ?? "nil")
        NSApplication.shared.setActivationPolicy(.regular)
        setupApplicationIcon()
    }

    private func setupApplicationIcon() {
        var iconImage: NSImage? = nil

        let candidates: [URL?] = [
            Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/Contents/Resources/AppIcon.icns"),
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/AppIcon.png"),
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("BibleStudy_BibleStudy.bundle/AppIcon.icns"),
            URL(fileURLWithPath: "BibleStudy/Sources/Resources/AppIcon.png"),
            URL(fileURLWithPath: "BibleStudy/Sources/Resources/AppIcon.icns"),
            URL(fileURLWithPath: "/Users/devln/RGDev/RGDev.App.BibleStudy/BibleStudy/Sources/Resources/AppIcon.png")
        ]

        for cand in candidates {
            if let url = cand, let img = NSImage(contentsOf: url) {
                iconImage = img
                break
            }
        }

        #if SWIFT_PACKAGE
        if iconImage == nil {
            if let moduleUrl = Bundle.module.url(forResource: "AppIcon", withExtension: "png") ??
                               Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
               let img = NSImage(contentsOf: moduleUrl) {
                iconImage = img
            }
        }
        #endif

        if let icon = iconImage {
            NSApplication.shared.applicationIconImage = icon
            print("✅ AppIcon successfully loaded and set to Dock")
        } else {
            print("⚠️ AppIcon could not be located in candidate paths")
        }
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
