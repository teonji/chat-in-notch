import SwiftUI
import UniformTypeIdentifiers

/// Chat view shared by the notch (compact) and the main window.
struct ChatView: View {
    var store: ChatStore
    var compact = false
    /// Changes value to bring focus back to the input field (e.g. when the notch opens).
    var focusTrigger = 0

    @State private var input = ""
    @State private var pending: [String] = []
    @State private var dropTargeted = false
    @State private var dictation = Dictation()
    @State private var dictationBase = ""
    @State private var silenceTask: Task<Void, Never>?
    @State private var listenTask: Task<Void, Never>?
    /// Voice conversation: after the reply is read aloud, the microphone reopens by itself.
    @State private var voiceMode = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messages
            if let warning = store.availabilityMessage ?? dictation.errorMessage {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
            inputBar
        }
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).strokeBorder(
                    Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6])
                )
                .padding(4).allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            attach(urls: urls)
            return !urls.isEmpty
        } isTargeted: {
            dropTargeted = $0
        }
        .onChange(of: store.isGeneratingSelected) { resumeVoiceIfNeeded() }
        .onChange(of: Speaker.shared.isSpeaking) { resumeVoiceIfNeeded() }
        .onChange(of: Speaker.shared.autoRead) { if !Speaker.shared.autoRead { voiceMode = false } }
        .onReceive(NotificationCenter.default.publisher(for: .notchDidCollapse)) { _ in
            guard compact else { return }
            voiceMode = false
            Task { await stopDictation() }
        }
        .onChange(of: focusTrigger) { focused = true }
        .onChange(of: store.selectedID) { focused = true }
        .onAppear { focused = true }
    }

    private var hasMessages: Bool { !(store.selected?.messages.isEmpty ?? true) }

    @ViewBuilder
    private var messages: some View {
        if hasMessages {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: compact ? 8 : 12) {
                        ForEach(store.selected?.messages ?? []) { MessageRow(message: $0, compact: compact) }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, compact ? 14 : 20)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.hidden)
                .onChange(of: store.tick) { proxy.scrollTo("bottom") }
                .onChange(of: store.selected?.messages.count) { proxy.scrollTo("bottom") }
                .onChange(of: store.selectedID) { proxy.scrollTo("bottom") }
            }
        } else {
            emptyState
        }
    }

    /// Starter prompts: tapping one pre-fills the input so the user only has to finish the sentence.
    private static let suggestions: [(label: String, prefix: String)] = [
        ("Explain something", "Explain "),
        ("Draft a message", "Draft a message about "),
        ("Make an image", "/image "),
    ]

    private var emptyState: some View {
        VStack(spacing: 0) {
            AppIconImage(side: compact ? 48 : 88)
                .shadow(color: Color.accentColor.opacity(0.35), radius: compact ? 14 : 22, y: 6)
            Text("Ask me anything")
                .font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                .padding(.top, compact ? 14 : 20)
            Text("On-device Apple model. Offline and private.")
                .font(compact ? .callout : .body)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            ViewThatFits {
                suggestionRow(axis: .horizontal)
                suggestionRow(axis: .vertical)
            }
            .padding(.top, compact ? 20 : 28)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, compact ? 14 : 20)
        .padding(.bottom, compact ? 8 : 24)  // optical centering between the header and the input bar
    }

    @ViewBuilder
    private func suggestionRow(axis: Axis) -> some View {
        let chips = ForEach(Self.suggestions, id: \.label) { item in
            Button {
                input = item.prefix
                focused = true
            } label: {
                Text(item.label)
                    .font(compact ? .callout : .body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain).clickable()
        }
        if axis == .horizontal {
            HStack(spacing: 8) { chips }
        } else {
            VStack(spacing: 8) { chips }
        }
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !pending.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(pending, id: \.self) { name in
                            ZStack(alignment: .topTrailing) {
                                Thumbnail(name: name, side: 52)
                                Button {
                                    pending.removeAll { $0 == name }
                                    ImageStorage.remove([name])
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.7))
                                }
                                .buttonStyle(.plain).clickable()
                                .accessibilityLabel("Remove image")
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(.top, 6).padding(.leading, 2)
                }
                .scrollIndicators(.hidden)
            }
            HStack(alignment: .bottom, spacing: 8) {
                Button(action: pickImages) {
                    Image(systemName: "paperclip").font(.system(size: 16, weight: .medium))
                        .frame(width: 28, height: 34)
                }
                .buttonStyle(.plain).clickable()
                .foregroundStyle(.secondary)
                .help("Attach images")
                .accessibilityLabel("Attach images")

                Button(action: toggleDictation) {
                    Group {
                        if dictation.isStarting {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: dictation.isRecording ? "mic.fill" : "mic")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(dictation.isRecording ? Color.red : .secondary)
                                .symbolEffect(.pulse, isActive: dictation.isRecording)
                        }
                    }
                    .frame(width: 28, height: 34)
                }
                .buttonStyle(.plain).clickable()
                .help(dictation.isRecording ? "Stop dictation" : "Dictate your message")
                .accessibilityLabel(dictation.isRecording ? "Stop dictation" : "Dictate your message")

                TextField("Type a message…", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($focused)
                    .onSubmit(send)
                    .onPasteCommand(of: [.image, .fileURL], perform: paste)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(compact ? 0.1 : 0.06), in: RoundedRectangle(cornerRadius: 16))

                Button(action: {
                    if store.isGeneratingSelected {
                        voiceMode = false
                        store.stop()
                    } else {
                        send()
                    }
                }) {
                    Image(systemName: store.isGeneratingSelected ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 28))
                }
                .buttonStyle(.plain).clickable()
                .foregroundStyle(canSend || store.isGeneratingSelected ? Color.accentColor : .secondary)
                .disabled(!canSend && !store.isGeneratingSelected)
                .accessibilityLabel(store.isGeneratingSelected ? "Stop reply" : "Send message")
            }
        }
        .padding(compact ? 10 : 14)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pending.isEmpty
    }

    private func send() {
        guard canSend, !store.isGeneratingSelected else { return }
        silenceTask?.cancel()
        if dictation.isRecording {
            // Wait for the final dictation text before sending.
            Task {
                await stopDictation()
                sendNow(byVoice: true)
            }
        } else {
            sendNow(byVoice: false)
        }
    }

    private func sendNow(byVoice: Bool) {
        guard canSend else { return }
        // Stay in voice conversation only if read-aloud is on and the message was dictated.
        voiceMode = byVoice && Speaker.shared.autoRead
        Speaker.shared.stop()
        store.send(input, images: pending)
        input = ""
        pending = []
    }

    // MARK: Dictation

    private func toggleDictation() {
        if dictation.isRecording {
            voiceMode = false
            Task { await stopDictation() }
        } else {
            startDictation()
        }
    }

    private func startDictation() {
        dictationBase = input
        store.pickerOpen = true  // keep the notch open during the permission prompt and listening
        Task {
            await dictation.start { text in
                let base = dictationBase
                input = base.isEmpty ? text : base + " " + text
                listenTask?.cancel()
                scheduleAutoSend()
            }
            if !dictation.isRecording {
                store.pickerOpen = false
                voiceMode = false
            } else {
                // Nobody is speaking: after 10 seconds the microphone turns off (and the voice conversation ends).
                listenTask = Task {
                    try? await Task.sleep(for: .seconds(10))
                    guard !Task.isCancelled, dictation.isRecording,
                        text(for: input) == text(for: dictationBase)
                    else { return }
                    voiceMode = false
                    await stopDictation()
                }
            }
            focused = true
        }
    }

    /// Once the reply has been generated and fully read, reopens the microphone.
    private func resumeVoiceIfNeeded() {
        guard voiceMode, Speaker.shared.autoRead, !store.isGeneratingSelected, !Speaker.shared.isSpeaking,
            !dictation.isRecording, !dictation.isStarting
        else { return }
        Task {
            // Short wait: keeps the microphone from picking up the tail of the voice.
            try? await Task.sleep(for: .milliseconds(500))
            guard voiceMode, Speaker.shared.autoRead, !store.isGeneratingSelected, !Speaker.shared.isSpeaking,
                !dictation.isRecording, !dictation.isStarting
            else { return }
            startDictation()
        }
    }

    /// If recognition produces no new text for a few seconds, the message sends itself.
    private func scheduleAutoSend() {
        silenceTask?.cancel()
        guard !text(for: input).isEmpty else { return }
        silenceTask = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled, dictation.isRecording else { return }
            send()
        }
    }

    private func text(for s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func stopDictation() async {
        silenceTask?.cancel()
        listenTask?.cancel()
        await dictation.stop()
        store.pickerOpen = false
    }

    // MARK: Attachments

    private func pickImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.message = "Choose the images to attach"
        store.pickerOpen = true
        NotificationCenter.default.post(name: .notchLowerLevel, object: nil)  // keep the picker above the notch
        NSApp.activate()
        panel.begin { response in
            NotificationCenter.default.post(name: .notchRestoreLevel, object: nil)
            store.pickerOpen = false
            if response == .OK { attach(urls: panel.urls) }
            focused = true
        }
    }

    private static let maxAttachments = 5

    private func attach(urls: [URL]) {
        let room = Self.maxAttachments - pending.count
        guard room > 0 else { return }
        let batch = Array(urls.prefix(room))
        // Decode and resize off the main thread: large photos would otherwise freeze the interface.
        Task.detached(priority: .userInitiated) {
            let names = batch.compactMap { ImageStorage.ingest(fileURL: $0) }
            await MainActor.run {
                pending.append(contentsOf: names.prefix(max(0, Self.maxAttachments - pending.count)))
            }
        }
    }

    private func paste(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    Task { @MainActor in attach(urls: [url]) }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data, let name = ImageStorage.ingest(data: data) else { return }
                    Task { @MainActor in
                        if pending.count < Self.maxAttachments {
                            pending.append(name)
                        } else {
                            ImageStorage.remove([name])
                        }
                    }
                }
            }
        }
    }
}

private struct MessageRow: View {
    let message: ChatMessage
    let compact: Bool

    var body: some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if let images = message.images, !images.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(images, id: \.self) {
                            Thumbnail(name: $0, side: isUser ? (compact ? 90 : 140) : (compact ? 220 : 320))
                        }
                    }
                }
                if message.text.isEmpty {
                    if !isUser && (message.images ?? []).isEmpty { ProgressView().controlSize(.small) }
                } else {
                    Text(rendered)
                        .textSelection(.enabled)
                        .font(compact ? .callout : .body)
                        .padding(.horizontal, isUser ? 12 : 0)
                        .padding(.vertical, isUser ? 8 : 2)
                        .background(
                            isUser ? Color.accentColor.opacity(0.85) : .clear, in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(isUser ? Color.white : Color.primary)
                    if !isUser {
                        Button {
                            Speaker.shared.toggle(message.text)
                        } label: {
                            Image(systemName: Speaker.shared.isSpeaking ? "speaker.slash" : "speaker.wave.2")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain).clickable()
                        .foregroundStyle(.secondary)
                        .help(Speaker.shared.isSpeaking ? "Stop reading" : "Read aloud")
                        .accessibilityLabel(Speaker.shared.isSpeaking ? "Stop reading" : "Read aloud")
                    }
                }
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }

    private var rendered: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: message.text, options: options)) ?? AttributedString(message.text)
    }
}

private struct Thumbnail: View {
    let name: String
    let side: CGFloat

    var body: some View {
        Group {
            if let image = ImageStorage.image(name) {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.3).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// App icon, loaded from the bundle resources.
struct AppIconImage: View {
    let side: CGFloat

    private static let image: NSImage? = Bundle.main.url(forResource: "app-icon", withExtension: "png")
        .flatMap { NSImage(contentsOf: $0) }

    var body: some View {
        if let image = Self.image {
            Image(nsImage: image).resizable().scaledToFit().frame(width: side, height: side)
        } else {
            Image(systemName: "sparkles").font(.system(size: side * 0.5)).frame(width: side, height: side)
        }
    }
}
