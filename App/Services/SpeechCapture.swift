import AVFoundation
import Combine
import Speech

/// On-device speech-to-text that stops by itself once you stop talking.
@MainActor
final class SpeechCapture: ObservableObject {
    enum State: Equatable {
        case idle, listening, denied, unavailable
    }

    @Published private(set) var state = State.idle
    @Published private(set) var transcript = ""

    /// Called once with the final text each time listening ends.
    var onFinished: ((String) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: .current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Task<Void, Never>?
    private var finishTimer: Task<Void, Never>?
    private var hasDelivered = true

    /// How long a pause counts as "done talking".
    private static let silenceTimeout: Duration = .seconds(1.3)
    /// Breadcrumbs are short, so never listen for long.
    private static let maximumListen: Duration = .seconds(10)

    func start() async {
        guard state != .listening else { return }
        guard await Self.requestPermissions() else {
            state = .denied
            return
        }
        guard let recognizer = recognizer, recognizer.isAvailable else {
            state = .unavailable
            return
        }

        transcript = ""
        hasDelivered = false
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }
            self.request = request

            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()
            state = .listening

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                Task { @MainActor in
                    guard let self else { return }
                    if let text, !text.isEmpty {
                        self.transcript = text
                        self.restartSilenceTimer()
                    }
                    if isFinal || error != nil {
                        self.finish()
                    }
                }
            }
            finishTimer = Task { [weak self] in
                try? await Task.sleep(for: Self.maximumListen)
                guard !Task.isCancelled else { return }
                self?.stop()
            }
        } catch {
            teardown()
            state = .unavailable
        }
    }

    /// Stops listening. `onFinished` fires as soon as the recognizer settles on a final result.
    func stop() {
        guard state == .listening else { return }
        silenceTimer?.cancel()
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        // The final result normally arrives within a few hundred milliseconds; don't wait forever.
        finishTimer?.cancel()
        finishTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    private func restartSilenceTimer() {
        silenceTimer?.cancel()
        silenceTimer = Task { [weak self] in
            try? await Task.sleep(for: Self.silenceTimeout)
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    private func finish() {
        guard !hasDelivered else { return }
        hasDelivered = true
        teardown()
        state = .idle
        onFinished?(transcript)
    }

    private func teardown() {
        silenceTimer?.cancel()
        finishTimer?.cancel()
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func requestPermissions() async -> Bool {
        let speechAllowed: Bool = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechAllowed else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}
