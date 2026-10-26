import AppKit

// Plain AppKit entry point: the app has no SwiftUI scenes (the main window and Settings are
// regular windows owned by AppDelegate), which keeps behavior predictable for a Dock-less app.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
