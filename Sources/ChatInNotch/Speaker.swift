import AVFoundation
import NaturalLanguage
import Observation

/// Read-aloud with system voices (offline). Can read replies sentence by sentence as they stream in.
@Observable @MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()

    var autoRead: Bool = UserDefaults.standard.bool(forKey: "autoRead") {
        didSet {
            UserDefaults.standard.set(autoRead, forKey: "autoRead")
            if !autoRead { stop() }
        }
    }
    private(set) var isSpeaking = false

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var queued: Set<ObjectIdentifier> = []
    @ObservationIgnored private var spokenOffsets: [UUID: Int] = [:]

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func stop() {
        spokenOffsets.removeAll()
        queued.removeAll()  // late didCancel events from old sentences must not affect the new ones
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    /// Reads a whole text (button on a message); a second click stops it.
    func toggle(_ text: String) {
        if isSpeaking { stop() } else { enqueue(text) }
    }

    /// Called on every streaming update: reads the complete sentences not yet read.
    func feed(id: UUID, text: String, final: Bool) {
        guard autoRead else { return }
        let start = spokenOffsets[id] ?? 0
        defer { if final { spokenOffsets[id] = nil } }
        guard text.count > start else { return }
        let rest = text.dropFirst(start)
        let end: String.Index?
        if final {
            end = rest.endIndex
        } else {
            end = Self.lastSentenceEnd(in: rest)
        }
        guard let end else { return }
        let chunk = String(rest[..<end])
        spokenOffsets[id] = start + chunk.count
        enqueue(chunk)
    }

    /// End of the last complete sentence: a period, ! or ? followed by whitespace, or a newline.
    /// (A period at the very end waits for the next character: it might be a decimal point.)
    private static func lastSentenceEnd(in s: Substring) -> String.Index? {
        var result: String.Index?
        var i = s.startIndex
        while i < s.endIndex {
            let next = s.index(after: i)
            if s[i] == "\n" {
                result = next
            } else if ".!?".contains(s[i]), next < s.endIndex, s[next].isWhitespace {
                result = next
            }
            i = next
        }
        return result
    }

    private func enqueue(_ raw: String) {
        let text = Self.clean(raw)
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        if let lang = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue {
            utterance.voice = AVSpeechSynthesisVoice(language: lang)
        }
        queued.insert(ObjectIdentifier(utterance))
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Strips the Markdown symbols that the voice would otherwise read aloud.
    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: "```", with: " ")
            .filter { !"*#`".contains($0) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceEnded(id) }
    }

    private func utteranceEnded(_ id: ObjectIdentifier) {
        queued.remove(id)
        if queued.isEmpty { isSpeaking = false }
    }
}
