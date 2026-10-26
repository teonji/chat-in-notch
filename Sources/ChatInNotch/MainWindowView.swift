import SwiftUI

struct MainWindowView: View {
    var store: ChatStore
    @State private var pendingDelete: Conversation?
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(get: { store.selectedID }, set: { store.select($0) })) {
                ForEach(store.conversations) { c in
                    ConversationRow(store: store, conversation: c) { pendingDelete = c }
                        .tag(c.id)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            .safeAreaInset(edge: .top, spacing: 0) { sidebarHeader }
            .safeAreaInset(edge: .bottom, spacing: 0) { sidebarFooter }
        } detail: {
            ChatView(store: store)
                .navigationTitle(store.selected?.title ?? "Chat in Notch")
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: Binding(get: { Speaker.shared.autoRead }, set: { Speaker.shared.autoRead = $0 })) {
                    Label("Read aloud", systemImage: Speaker.shared.autoRead ? "speaker.wave.2.fill" : "speaker.slash")
                }
                .help("Read replies aloud")
            }
        }
        .alert(
            "Delete this conversation?",
            isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }
            ), presenting: pendingDelete
        ) { c in
            Button("Delete", role: .destructive) { store.delete(c.id) }
            Button("Cancel", role: .cancel) {}
        } message: { c in
            Text("“\(c.title)” will be permanently deleted.")
        }
        .alert("Delete all conversations?", isPresented: $confirmDeleteAll) {
            Button("Delete all", role: .destructive) { store.deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    /// Live status of the on-device model plus a shortcut to Settings.
    private var sidebarFooter: some View {
        let status = ModelStatus.current
        return HStack(spacing: 10) {
            Circle()
                .fill(status.isReady ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Apple Foundation Models").font(.callout.weight(.medium))
                Text(status.isReady ? "Ready · on-device" : status.text)
                    .font(.caption)
                    .foregroundStyle(status.isReady ? Color.secondary : Color.orange)
            }
            Spacer(minLength: 0)
            Button {
                AppDelegate.shared?.showSettings()
            } label: {
                Image(systemName: "gearshape").font(.system(size: 15))
            }
            .buttonStyle(.plain).clickable()
            .foregroundStyle(.secondary)
            .help("Settings")
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .overlay(alignment: .top) { Divider() }
    }

    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Button {
                store.newChat()
            } label: {
                Label("New chat", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain).clickable()
            Menu {
                Button("Delete all…", role: .destructive) { confirmDeleteAll = true }
                    .disabled(store.conversations.isEmpty)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton).clickable()
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct ConversationRow: View {
    var store: ChatStore
    let conversation: Conversation
    let onDelete: () -> Void

    @State private var hovering = false
    @State private var editing = false
    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                if editing {
                    TextField("Title", text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .focused($fieldFocused)
                        .onSubmit(commit)
                        .onExitCommand { editing = false }
                        .onChange(of: fieldFocused) { if !fieldFocused { commit() } }
                } else {
                    Text(conversation.title).lineLimit(1)
                    Text(
                        conversation.messages.isEmpty
                            ? "No messages"
                            : conversation.updatedAt.formatted(.relative(presentation: .named))
                    )
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if hovering && !editing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless).clickable()
                .foregroundStyle(.secondary)
                .help("Delete")
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(count: 2, perform: beginEditing)
        .contextMenu {
            Button("Rename", action: beginEditing)
            Button("Delete…", role: .destructive, action: onDelete)
        }
    }

    private func beginEditing() {
        draft = conversation.title
        editing = true
        fieldFocused = true
    }

    private func commit() {
        guard editing else { return }
        editing = false
        store.rename(conversation.id, to: draft)
    }
}
