import AppKit
import SwiftUI

extension Notification.Name {
    static let notchDidCollapse = Notification.Name("notchDidCollapse")
    /// Posted before a regular window (file picker, Image Playground) opens: the notch panel sits above
    /// normal windows, so it must step down to let them show.
    static let notchLowerLevel = Notification.Name("notchLowerLevel")
    static let notchRestoreLevel = Notification.Name("notchRestoreLevel")
}

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the panel above the notch and decides when to expand/collapse it based on the mouse.
@MainActor
final class NotchController {
    let model = NotchModel()
    private let panel: NotchPanel
    private var monitors: [Any] = []
    private var collapseWork: DispatchWorkItem?
    private var expandWork: DispatchWorkItem?

    private let store: ChatStore
    /// False while the standalone window is open: the notch does not react to the mouse.
    var hoverEnabled = true {
        didSet { if !hoverEnabled { collapse() } }
    }

    init(store: ChatStore) {
        self.store = store
        let size = NotchView.expandedSize
        panel = NotchPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .mainMenu + 3
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovable = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        let host = NSHostingView(rootView: NotchView(model: model, store: store))
        host.sizingOptions = []
        panel.contentView = host
        position()
        panel.orderFrontRegardless()

        model.onCollapse = { [weak self] in self?.collapse() }
        model.onOpenApp = { [weak self] in
            self?.collapse()
            AppDelegate.shared?.showMainWindow()
        }

        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown]
        if let g = NSEvent.addGlobalMonitorForEvents(
            matching: mask,
            handler: { [weak self] e in
                Task { @MainActor in self?.handle(e.type) }
            })
        {
            monitors.append(g)
        }
        if let l = NSEvent.addLocalMonitorForEvents(
            matching: mask,
            handler: { [weak self] e in
                self?.handle(e.type)
                return e
            })
        {
            monitors.append(l)
        }

        NotificationCenter.default.addObserver(forName: .notchLowerLevel, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.panel.level = .normal }
        }
        NotificationCenter.default.addObserver(forName: .notchRestoreLevel, object: nil, queue: .main) {
            [weak self] _ in
            Task { @MainActor in self?.panel.level = .mainMenu + 3 }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.model.geometry = NotchGeometry.current()
                self.position()
            }
        }
    }

    /// Centers the panel at the top of the screen that has the notch.
    private func position() {
        let screen = model.geometry.screen.frame
        let size = NotchView.expandedSize
        panel.setFrame(
            CGRect(
                x: screen.midX - size.width / 2, y: screen.maxY - size.height,
                width: size.width, height: size.height), display: true)
    }

    // MARK: Hover

    /// Zone that reacts to the mouse: the notch plus a little margin.
    private var triggerRect: CGRect {
        let g = model.geometry
        let f = g.screen.frame
        let w = g.size.width + 16
        let h = g.size.height + 2
        return CGRect(x: f.midX - w / 2, y: f.maxY - h, width: w, height: h + 10)
    }

    /// While open, the mouse may stay inside the panel (plus a small margin).
    private var keepOpenRect: CGRect { panel.frame.insetBy(dx: -12, dy: -12) }

    private func handle(_ type: NSEvent.EventType) {
        let p = NSEvent.mouseLocation
        if !hoverEnabled { return }
        if store.pickerOpen { return }  // file picker or dictation active: stay open
        if model.isExpanded {
            if type != .mouseMoved && !panel.frame.contains(p) {
                collapse()  // click outside
            } else if keepOpenRect.contains(p) || triggerRect.contains(p) {
                collapseWork?.cancel()
                collapseWork = nil
            } else if collapseWork == nil {
                let work = DispatchWorkItem { [weak self] in self?.collapse() }
                collapseWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
            }
        } else if type == .mouseMoved {
            if triggerRect.contains(p) {
                guard expandWork == nil else { return }
                let work = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    self.expandWork = nil
                    if self.triggerRect.contains(NSEvent.mouseLocation) { self.expand() }
                }
                expandWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
            } else {
                expandWork?.cancel()
                expandWork = nil
            }
        }
    }

    func expand() {
        collapseWork?.cancel()
        collapseWork = nil
        model.geometry = NotchGeometry.current()
        position()
        panel.ignoresMouseEvents = false
        panel.makeKeyAndOrderFront(nil)
        model.isExpanded = true
        model.focusTrigger += 1
    }

    func collapse() {
        collapseWork?.cancel()
        collapseWork = nil
        expandWork?.cancel()
        expandWork = nil
        store.pickerOpen = false
        NotificationCenter.default.post(name: .notchDidCollapse, object: nil)  // stops any dictation in progress
        model.isExpanded = false
        panel.ignoresMouseEvents = true
        panel.resignKey()
    }
}
