import Observation
import SwiftUI

struct NotchGeometry {
    let screen: NSScreen
    let size: CGSize
    let hasNotch: Bool

    static func current() -> NotchGeometry {
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens[0]
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea,
            screen.safeAreaInsets.top > 0
        {
            let width = screen.frame.width - left.width - right.width
            return NotchGeometry(
                screen: screen, size: CGSize(width: width, height: screen.safeAreaInsets.top), hasNotch: true)
        }
        return NotchGeometry(screen: screen, size: CGSize(width: 190, height: 32), hasNotch: false)
    }
}

@Observable @MainActor
final class NotchModel {
    var isExpanded = false
    var geometry = NotchGeometry.current()
    var focusTrigger = 0
    var showHistory = false
    var onOpenApp: () -> Void = {}
    /// Closes the panel through the controller (also updates the window, not just the state).
    var onCollapse: () -> Void = {}
}

/// Notch shape: concave top corners (they blend into the screen edge), rounded bottom corners.
struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(
            to: CGPoint(x: r.minX + topRadius, y: r.minY + topRadius),
            control: CGPoint(x: r.minX + topRadius, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + topRadius, y: r.maxY - bottomRadius))
        p.addQuadCurve(
            to: CGPoint(x: r.minX + topRadius + bottomRadius, y: r.maxY),
            control: CGPoint(x: r.minX + topRadius, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - topRadius - bottomRadius, y: r.maxY))
        p.addQuadCurve(
            to: CGPoint(x: r.maxX - topRadius, y: r.maxY - bottomRadius),
            control: CGPoint(x: r.maxX - topRadius, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - topRadius, y: r.minY + topRadius))
        p.addQuadCurve(
            to: CGPoint(x: r.maxX, y: r.minY),
            control: CGPoint(x: r.maxX - topRadius, y: r.minY))
        p.closeSubpath()
        return p
    }
}

struct NotchView: View {
    static let expandedSize = CGSize(width: 620, height: 420)

    var model: NotchModel
    var store: ChatStore

    var body: some View {
        let expanded = model.isExpanded
        let notch = model.geometry.size
        let size = expanded ? Self.expandedSize : notch

        ZStack(alignment: .top) {
            NotchShape(topRadius: expanded ? 18 : 6, bottomRadius: expanded ? 28 : 10)
                .fill(.black)
                .shadow(color: .black.opacity(expanded ? 0.5 : 0), radius: 14, y: 6)
                // Nothing is drawn when closed (the physical notch is already black); it appears right away
                // on opening and fades out only at the end of the shrink.
                .opacity(expanded ? 1 : 0)
                .animation(expanded ? .none : .easeOut(duration: 0.12).delay(0.3), value: expanded)

            content(notchHeight: notch.height, notchWidth: notch.width)
                .opacity(expanded ? 1 : 0)
                .scaleEffect(expanded ? 1 : 0.92, anchor: .top)
                .blur(radius: expanded ? 0 : 8)
                .allowsHitTesting(expanded)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .frame(width: Self.expandedSize.width, height: Self.expandedSize.height, alignment: .top)
        .animation(.spring(response: 0.42, dampingFraction: 0.76), value: expanded)
        .environment(\.colorScheme, .dark)
        .onChange(of: model.isExpanded) { if !model.isExpanded { model.showHistory = false } }
        .onKeyPress(.escape) {
            model.onCollapse()
            return .handled
        }
    }

    private func content(notchHeight: CGFloat, notchWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Bar at the same height as the physical notch: the buttons sit on its sides.
            HStack {
                headerButton("square.and.pencil", help: "New chat") {
                    store.newChat()
                    model.showHistory = false
                    model.focusTrigger += 1
                }
                headerButton("clock.arrow.circlepath", help: "History") { model.showHistory.toggle() }
                    .foregroundStyle(model.showHistory ? Color.accentColor : .white.opacity(0.75))
                // Leave the physical notch area free: the buttons stay on its sides.
                Spacer(minLength: notchWidth + 8)
                if let title = store.selected?.title, !(store.selected?.messages.isEmpty ?? true) {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 80, alignment: .trailing)
                        .padding(.trailing, 4)
                        .layoutPriority(-1)
                }
                headerButton(
                    Speaker.shared.autoRead ? "speaker.wave.2.fill" : "speaker.slash",
                    help: Speaker.shared.autoRead ? "Read-aloud on" : "Read-aloud off"
                ) {
                    Speaker.shared.autoRead.toggle()
                }
                headerButton("arrow.up.left.and.arrow.down.right", help: "Open in app") { model.onOpenApp() }
                Menu {
                    Button("Settings…") { AppDelegate.shared?.showSettings() }
                    Divider()
                    Button("Quit Chat in Notch") { NSApp.terminate(nil) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton).clickable()
                .menuIndicator(.hidden)
                .fixedSize()
                .foregroundStyle(.white.opacity(0.75))
                .help("More")
                .accessibilityLabel("More")
            }
            .padding(.horizontal, 36)
            .frame(height: max(notchHeight, 32))

            ZStack {
                // Stays alive under the history so the draft is not lost.
                ChatView(store: store, compact: true, focusTrigger: model.focusTrigger)
                    .opacity(model.showHistory ? 0 : 1)
                    .allowsHitTesting(!model.showHistory)
                if model.showHistory {
                    HistoryList(store: store) {
                        model.showHistory = false
                        model.focusTrigger += 1
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.15), value: model.showHistory)
            // The black body is inset by the shape's top radius (18pt) on each side, so the content
            // needs that inset plus its own margin to look evenly spaced.
            .padding(.horizontal, 24)
            .padding(.bottom, 2)
        }
    }

    private func headerButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).clickable()
        .foregroundStyle(.white.opacity(0.75))
        .help(help)
        .accessibilityLabel(help)
    }
}

/// List of saved conversations, shown inside the notch.
private struct HistoryList: View {
    var store: ChatStore
    let onPick: () -> Void
    @State private var confirming: UUID?

    private var items: [Conversation] { store.conversations.filter { !$0.messages.isEmpty } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if items.isEmpty {
                    Text("No conversations")
                        .font(.callout).foregroundStyle(.secondary)
                        .padding(.top, 60)
                }
                ForEach(items) { c in row(c) }
            }
            .padding(.vertical, 6)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func row(_ c: Conversation) -> some View {
        if confirming == c.id {
            HStack {
                Text("Delete “\(c.title)”?").font(.callout).lineLimit(1)
                Spacer()
                Button("Cancel") { confirming = nil }.buttonStyle(.plain).clickable().foregroundStyle(.secondary)
                Button("Delete") {
                    store.delete(c.id)
                    confirming = nil
                }
                .buttonStyle(.plain).clickable().foregroundStyle(.red)
            }
            .font(.callout)
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        } else {
            HistoryRow(
                conversation: c, selected: c.id == store.selectedID,
                onOpen: {
                    store.select(c.id)
                    onPick()
                },
                onDelete: { confirming = c.id })
        }
    }
}

private struct HistoryRow: View {
    let conversation: Conversation
    let selected: Bool
    let onOpen: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(conversation.title).font(.callout).lineLimit(1)
                Text(conversation.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if hovering {
                Button(action: onDelete) { Image(systemName: "trash").font(.system(size: 12)) }
                    .buttonStyle(.plain).clickable().foregroundStyle(.secondary).help("Delete")
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(
            selected ? Color.white.opacity(0.12) : hovering ? Color.white.opacity(0.07) : .clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .clickable()
        .onHover { hovering = $0 }
    }
}
