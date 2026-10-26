import Foundation
import FoundationModels
import ImagePlayground
import Observation

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable { case user, assistant }
    var id = UUID()
    var role: Role
    var text: String
    /// File names in ImageStorage (optional so older saved conversations still decode).
    var images: [String]? = nil
}

let defaultChatTitle = "New chat"

struct Conversation: Identifiable, Codable, Hashable {
    var id = UUID()
    var title = defaultChatTitle
    var messages: [ChatMessage] = []
    var updatedAt = Date()
}

/// State shared by the notch and the window: conversations, selection, generation with the on-device model.
@Observable @MainActor
final class ChatStore {
    private(set) var conversations: [Conversation] = []
    var selectedID: UUID?
    private(set) var generating: Set<UUID> = []
    /// Incremented on every streaming update, used for auto-scroll.
    private(set) var tick = 0

    @ObservationIgnored private var sessions: [UUID: LanguageModelSession] = [:]
    @ObservationIgnored private var tasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private let fileURL: URL
    /// True while a file picker or dictation is active: the notch must not close.
    @ObservationIgnored var pickerOpen = false

    private static let systemPrompt =
        "You are a helpful, precise and concise assistant. Reply in the language the user writes in."

    init() {
        let dir = AppPaths.support
        fileURL = dir.appendingPathComponent("conversations.json")
        load()
        selectedID = conversations.first?.id
    }

    var selected: Conversation? { conversations.first { $0.id == selectedID } }
    var isGeneratingSelected: Bool { selectedID.map(generating.contains) ?? false }

    var availabilityMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available: nil
        case .unavailable(.deviceNotEligible): "This Mac does not support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled): "Turn on Apple Intelligence in System Settings."
        case .unavailable(.modelNotReady): "The model is still downloading, try again shortly."
        case .unavailable: "The on-device model is not available."
        }
    }

    // MARK: Conversations

    func newChat() {
        // Reuse an existing empty chat instead of piling them up.
        if let empty = conversations.first(where: { $0.messages.isEmpty }) {
            select(empty.id)
            return
        }
        let c = Conversation()
        conversations.insert(c, at: 0)
        select(c.id)
    }

    /// Selects a conversation; chats left empty (and not selected) are discarded.
    func select(_ id: UUID?) {
        selectedID = id
        conversations.removeAll { $0.messages.isEmpty && $0.id != id }
    }

    func rename(_ id: UUID, to title: String) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let i = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[i].title = t
        save()
    }

    func delete(_ id: UUID) {
        Speaker.shared.stop()
        tasks[id]?.cancel()
        tasks[id] = nil
        sessions[id] = nil
        generating.remove(id)
        conversations.first { $0.id == id }.map(removeImages)
        conversations.removeAll { $0.id == id }
        if selectedID == id { select(conversations.first?.id) }
        save()
    }

    func deleteAll() {
        for task in tasks.values { task.cancel() }
        tasks.removeAll()
        sessions.removeAll()
        generating.removeAll()
        for conversation in conversations { removeImages(of: conversation) }
        conversations.removeAll()
        selectedID = nil
        save()
    }

    // MARK: Sending

    func send(_ raw: String, images: [String] = []) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !images.isEmpty else { return }
        if selected == nil { newChat() }
        guard let id = selectedID, !generating.contains(id),
            let index = conversations.firstIndex(where: { $0.id == id })
        else { return }

        let priorMessages = conversations[index].messages
        let session = sessions[id] ?? makeSession(from: priorMessages)
        sessions[id] = session

        let reply = ChatMessage(role: .assistant, text: "")
        if conversations[index].title == defaultChatTitle {
            conversations[index].title = text.isEmpty ? "Image" : String(text.prefix(40))
        }
        conversations[index].messages.append(
            ChatMessage(role: .user, text: text, images: images.isEmpty ? nil : images))
        conversations[index].messages.append(reply)
        touch(id)
        generating.insert(id)
        save()  // the message must not be lost if the app quits during the reply

        if let prompt = Self.imageCommandPrompt(in: text) {
            tasks[id] = Task { [weak self] in
                await self?.generateImage(prompt: prompt, conversation: id, reply: reply.id)
                self?.finish(id)
            }
            return
        }

        let promptText = text.isEmpty ? "Describe this image." : text
        let imageURLs = images.map(ImageStorage.url)
        tasks[id] = Task { [weak self] in
            var session = session
            var retried = false
            while true {
                do {
                    let stream = session.streamResponse {
                        promptText
                        for url in imageURLs { Attachment(imageURL: url) }
                    }
                    for try await snapshot in stream {
                        self?.update(id, reply.id, snapshot.content)
                        Speaker.shared.feed(id: reply.id, text: snapshot.content, final: false)
                    }
                    if let text = self?.messageText(id, reply.id) {
                        Speaker.shared.feed(id: reply.id, text: text, final: true)
                    }
                    break
                } catch is CancellationError {
                    Speaker.shared.stop()
                    break
                } catch let error as LanguageModelError {
                    // Conversation too long for the context window: restart once from a recent summary.
                    if case .contextSizeExceeded = error, !retried, let self {
                        retried = true
                        session = self.makeSession(from: priorMessages)
                        self.sessions[id] = session
                        self.update(id, reply.id, "")
                        continue
                    }
                    self?.sessions[id] = nil
                    self?.fail(id, reply.id, error)
                    break
                } catch {
                    self?.sessions[id] = nil  // the next request rebuilds the context
                    self?.fail(id, reply.id, error)
                    break
                }
            }
            self?.finish(id)
        }
    }

    /// If the text is "/image <description>", returns the description (possibly empty).
    private static func imageCommandPrompt(in text: String) -> String? {
        for command in ["/image"] where text.lowercased().hasPrefix(command) {
            let rest = text.dropFirst(command.count)
            if rest.isEmpty || rest.first!.isWhitespace {
                return rest.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func generateImage(prompt: String, conversation cid: UUID, reply mid: UUID) async {
        guard !prompt.isEmpty else {
            update(cid, mid, "Write what you want to generate, for example: /image an astronaut cat")
            return
        }
        do {
            let creator = try await ImageCreator()
            let style = creator.availableStyles.first ?? .illustration
            for try await created in creator.images(for: [.text(prompt)], style: style, limit: 1) {
                guard let name = ImageStorage.ingest(cgImage: created.cgImage) else { continue }
                setImages(cid, mid, [name])
            }
        } catch is CancellationError {
        } catch let error as ImageCreator.Error {
            if (error == .notSupported || error == .unavailable) && ImagePlaygroundPanel.isAvailable {
                await generateWithPanel(prompt: prompt, conversation: cid, reply: mid)
            } else {
                fail(cid, mid, message: Self.describe(error))
            }
        } catch {
            fail(cid, mid, message: error.localizedDescription)
        }
    }

    /// `ImageCreator` rejects the app: fall back to Apple's official Image Playground panel.
    private func generateWithPanel(prompt: String, conversation cid: UUID, reply mid: UUID) async {
        guard let url = await ImagePlaygroundPanel.generate(prompt: prompt) else {
            update(cid, mid, "Generazione annullata.")
            return
        }
        defer { try? FileManager.default.removeItem(at: url) }
        if let name = ImageStorage.ingest(fileURL: url) {
            setImages(cid, mid, [name])
        } else {
            fail(cid, mid, message: "Could not read the generated image.")
        }
    }

    private static func describe(_ error: ImageCreator.Error) -> String {
        switch error {
        case .notSupported, .unavailable:
            "Image generation is unavailable: this app cannot use Image Playground on this Mac. Try opening the Image Playground app once to download its model."
        case .unsupportedLanguage: "The language of the description is not supported: try English."
        case .backgroundCreationForbidden: "Generation is not allowed while the app is in the background."
        case .creationFailed: "Generation failed, try a different description."
        default: "Generation failed (\(error))."
        }
    }

    private func setImages(_ cid: UUID, _ mid: UUID, _ names: [String]) {
        guard let ci = conversations.firstIndex(where: { $0.id == cid }),
            let mi = conversations[ci].messages.firstIndex(where: { $0.id == mid })
        else { return }
        conversations[ci].messages[mi].images = (conversations[ci].messages[mi].images ?? []) + names
        tick &+= 1
    }

    func stop() {
        guard let id = selectedID else { return }
        tasks[id]?.cancel()
    }

    // MARK: Internals

    private func removeImages(of c: Conversation) {
        ImageStorage.remove(c.messages.flatMap { $0.images ?? [] })
    }

    /// Rebuilds the context of a session from a saved conversation.
    private func makeSession(from history: [ChatMessage]) -> LanguageModelSession {
        var instructions = Self.systemPrompt
        let recent = history.filter { !$0.text.isEmpty || $0.images != nil }.suffix(10)
        if !recent.isEmpty {
            let recap = recent.map {
                ($0.role == .user ? "User: " : "Assistant: ") + String($0.text.prefix(600))
                    + ($0.images == nil ? "" : $0.role == .user ? " [attached image]" : " [generated image]")
            }
            .joined(separator: "\n")
            instructions += "\n\nPrevious conversation to continue from:\n\(recap)"
        }
        return LanguageModelSession(instructions: instructions)
    }

    private func messageText(_ cid: UUID, _ mid: UUID) -> String? {
        conversations.first { $0.id == cid }?.messages.first { $0.id == mid }?.text
    }

    private func update(_ cid: UUID, _ mid: UUID, _ text: String) {
        guard let ci = conversations.firstIndex(where: { $0.id == cid }),
            let mi = conversations[ci].messages.firstIndex(where: { $0.id == mid })
        else { return }
        conversations[ci].messages[mi].text = text
        tick &+= 1
    }

    private func fail(_ cid: UUID, _ mid: UUID, _ error: Error) {
        fail(cid, mid, message: error.localizedDescription)
    }

    private func fail(_ cid: UUID, _ mid: UUID, message: String) {
        guard let ci = conversations.firstIndex(where: { $0.id == cid }),
            let mi = conversations[ci].messages.firstIndex(where: { $0.id == mid })
        else { return }
        let current = conversations[ci].messages[mi].text
        let note = "Error: \(message)"
        conversations[ci].messages[mi].text = current.isEmpty ? note : current + "\n\n" + note
    }

    private func finish(_ id: UUID) {
        generating.remove(id)
        tasks[id] = nil
        touch(id)
        save()
    }

    private func touch(_ id: UUID) {
        guard let i = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[i].updatedAt = Date()
        let c = conversations.remove(at: i)
        conversations.insert(c, at: 0)
    }

    // MARK: Local persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
        } catch {
            // Unreadable file: keep it aside, otherwise the next save would overwrite it.
            let name = "conversations.corrupted-\(Int(Date().timeIntervalSince1970)).json"
            try? FileManager.default.copyItem(
                at: fileURL, to: fileURL.deletingLastPathComponent().appendingPathComponent(name))
        }
    }

    func save() {
        let persisted = conversations.filter { !$0.messages.isEmpty }
        guard let data = try? JSONEncoder().encode(persisted) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
