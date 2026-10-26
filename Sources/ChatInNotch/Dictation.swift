import AVFoundation
import Observation
import Speech

/// On-device dictation with SpeechAnalyzer: recognized text arrives in real time.
@Observable @MainActor
final class Dictation {
    private(set) var isRecording = false
    private(set) var isStarting = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var analyzer: SpeechAnalyzer?
    @ObservationIgnored private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    @ObservationIgnored private var resultsTask: Task<Void, Never>?
    /// Set if a stop is requested while startup (e.g. a permission request) is still in progress.
    @ObservationIgnored private var cancelRequested = false

    /// Starts listening; `onText` receives the text recognized so far (cumulative).
    func start(onText: @escaping @MainActor (String) -> Void) async {
        guard !isRecording, !isStarting else { return }
        isStarting = true
        cancelRequested = false
        errorMessage = nil
        defer { isStarting = false }
        do {
            guard await AVAudioApplication.requestRecordPermission() else {
                throw DictationError("Allow microphone access in System Settings › Privacy & Security.")
            }
            guard SpeechTranscriber.isAvailable else { throw DictationError("Dictation is not available on this Mac.") }
            let locale =
                await SpeechTranscriber.supportedLocale(equivalentTo: .current)
                ?? Locale(identifier: "it-IT")
            let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

            // Download the speech model for the language if it is missing (only once).
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }

            guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                throw DictationError("Unsupported audio format.")
            }
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
            // Register them right away: if something fails later, teardown() releases them.
            self.analyzer = analyzer
            inputContinuation = continuation

            resultsTask = Task {
                var finalized = ""
                do {
                    for try await result in transcriber.results {
                        let piece = String(result.text.characters)
                        if result.isFinal {
                            finalized += piece
                            onText(finalized)
                        } else {
                            onText(finalized + piece)
                        }
                    }
                } catch {}
            }
            try await analyzer.start(inputSequence: stream)

            let input = engine.inputNode
            let inputFormat = input.outputFormat(forBus: 0)
            guard let converter = AVAudioConverter(from: inputFormat, to: format) else {
                throw DictationError("The microphone cannot be used.")
            }
            // Deprecated in macOS 27 in favor of a throwing overload that Swift does not expose cleanly yet,
            // so the long-standing call is kept (it produces one known deprecation warning).
            input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
                let ratio = format.sampleRate / inputFormat.sampleRate
                let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
                guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return }
                var supplied = false
                var error: NSError?
                converter.convert(to: out, error: &error) { _, status in
                    if supplied {
                        status.pointee = .noDataNow
                        return nil
                    }
                    supplied = true
                    status.pointee = .haveData
                    return buffer
                }
                if error == nil, out.frameLength > 0 { continuation.yield(AnalyzerInput(buffer: out)) }
            }
            engine.prepare()
            try engine.start()

            isRecording = true
            if cancelRequested { await teardown(finalize: false) }
        } catch {
            errorMessage = (error as? DictationError)?.message ?? error.localizedDescription
            await teardown(finalize: false)
        }
    }

    func stop() async {
        if isStarting {
            cancelRequested = true
            return
        }
        guard isRecording else { return }
        await teardown(finalize: true)
    }

    private func teardown(finalize: Bool) async {
        isRecording = false
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        inputContinuation?.finish()
        inputContinuation = nil
        if let analyzer {
            if finalize {
                try? await analyzer.finalizeAndFinishThroughEndOfInput()
            } else {
                await analyzer.cancelAndFinishNow()
            }
        }
        analyzer = nil
        if finalize { await resultsTask?.value } else { resultsTask?.cancel() }
        resultsTask = nil
    }
}

private struct DictationError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
