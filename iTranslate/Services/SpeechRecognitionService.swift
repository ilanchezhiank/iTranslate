//
//  SpeechRecognitionService.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import Speech
import AVFoundation

/// Live microphone dictation using SFSpeechRecognizer.
nonisolated final class SpeechRecognitionService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    func start(onResult: @escaping @Sendable (String, Bool) -> Void) throws {
        stop()
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result {
                onResult(result.bestTranscription.formattedString, result.isFinal)
            } else if error != nil {
                onResult("", true)
            }
        }

        Self.installTap(on: audioEngine, request: request)
        audioEngine.prepare()
        try audioEngine.start()
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    // nonisolated so the real-time audio callback doesn't inherit any actor isolation.
    private nonisolated static func installTap(on engine: AVAudioEngine, request: SFSpeechAudioBufferRecognitionRequest) {
        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
    }
}
