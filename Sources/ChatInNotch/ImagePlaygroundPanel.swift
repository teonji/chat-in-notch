import AppKit
import ImagePlayground

/// Fallback when `ImageCreator` is unusable: opens Apple's Image Playground panel
/// pre-filled with the description and returns the URL of the chosen image (nil if cancelled).
@MainActor
final class ImagePlaygroundPanel: NSObject, ImagePlaygroundViewController.Delegate, NSWindowDelegate {
    private var window: NSWindow?
    private var continuation: CheckedContinuation<URL?, Never>?
    private static var active: ImagePlaygroundPanel?  // keeps the panel alive while it is open

    static var isAvailable: Bool { ImagePlaygroundViewController.isAvailable }

    static func generate(prompt: String) async -> URL? {
        let panel = ImagePlaygroundPanel()
        active = panel
        defer { active = nil }
        return await panel.present(prompt: prompt)
    }

    private func present(prompt: String) async -> URL? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let controller = ImagePlaygroundViewController()
            controller.concepts = [.text(prompt)]
            controller.delegate = self
            let window = NSWindow(contentViewController: controller)
            window.title = "Image Playground"
            window.styleMask = [.titled, .closable, .resizable]
            window.setContentSize(NSSize(width: 720, height: 640))
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
            NotificationCenter.default.post(name: .notchLowerLevel, object: nil)
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func finish(_ url: URL?) {
        guard let continuation else { return }
        self.continuation = nil
        NotificationCenter.default.post(name: .notchRestoreLevel, object: nil)
        let w = window
        window = nil
        w?.delegate = nil
        w?.close()
        continuation.resume(returning: url)
    }

    func imagePlaygroundViewController(
        _ imagePlaygroundViewController: ImagePlaygroundViewController, didCreateImageAt imageURL: URL
    ) {
        finish(imageURL)
    }

    func imagePlaygroundViewControllerDidCancel(_ imagePlaygroundViewController: ImagePlaygroundViewController) {
        finish(nil)
    }

    func windowWillClose(_ notification: Notification) { finish(nil) }
}
