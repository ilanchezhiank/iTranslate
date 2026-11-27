//
//  TranslateViewModel.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import SwiftUI
import Translation

@MainActor @Observable
final class TranslateViewModel {
    enum Phase: Equatable {
        case idle, translating, validating
        case done(TranslationRecord)
        case failed(String)
    }

    // Input state
    var inputText = ""
    var isRecording = false
    private(set) var phase: Phase = .idle

    //    // Language (Spanish for now; swap for a picker later)
    //    let targetLanguage = Locale.Language(identifier: "es")
    //    let targetLanguageName = "Spanish"
    private(set) var targetLanguage: AppLanguage
    private(set) var availableLanguages: [AppLanguage]
    private let languageService: LanguageServicing
    private static let languageKey = "targetLanguageID"

    /// Drives the `.translationTask` modifier in the view.
    var configuration: TranslationSession.Configuration?

    private let translator: TranslationServicing
    private let validator: ValidationServicing
    private let speech: SpeechRecognitionService
    private let onComplete: (TranslationRecord) -> Void

    init(
        translator: TranslationServicing = TranslationService(),
        validator: ValidationServicing = ValidationService(),
        speech: SpeechRecognitionService = SpeechRecognitionService(),
        languageService: LanguageServicing = LanguageService(),
        onComplete: @escaping (TranslationRecord) -> Void = { _ in }
    ) {
        self.translator = translator
        self.validator = validator
        self.speech = speech
        self.languageService = languageService
        self.onComplete = onComplete

        let saved =
            UserDefaults.standard.string(forKey: Self.languageKey) ?? "es"
        let initial = AppLanguage(Locale.Language(identifier: saved))
        self.targetLanguage = initial
        self.availableLanguages = [initial]
    }

    //    init(translator: TranslationServicing? = nil,
    //         validator: ValidationServicing? = nil,
    //         speech: SpeechRecognitionService? = nil,
    //         onComplete: @escaping (TranslationRecord) -> Void = { _ in }) {
    //        self.translator = translator ?? TranslationService()
    //        self.validator = validator ?? ValidationService()
    //        self.speech = speech ?? SpeechRecognitionService()
    //        self.onComplete = onComplete
    //    }

    var isBusy: Bool { phase == .translating || phase == .validating }
    var canTranslate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isBusy
    }

    // MARK: Translate

    func translateTapped() {
        guard canTranslate else {
            if inputText.isEmpty {
                phase = .failed(AppError.emptyInput.localizedDescription)
            }
            return
        }
        stopRecording()
        phase = .translating
        // Setting a new configuration (or invalidating) re-triggers the view's translationTask.
        if configuration == nil {
//            configuration = .init(source: nil, target: targetLanguage)
            configuration = .init(source: nil, target: targetLanguage.language)
        } else {
            configuration?.invalidate()
        }
    }

    /// Called from the view's `.translationTask` closure.
    func runTranslation(with session: TranslationSession) async {
        let original = inputText
        do {
            let translated = try await translator.translate(
                original,
                using: session
            )
            phase = .validating

            let langName = targetLanguage.name

            // Validation failure shouldn't discard a good translation.
            let validation = try? await validator.validate(
                original: original,
                translated: translated,
                targetLanguage: langName
            )
            let record = TranslationRecord(
                original: original,
                translated: translated,
                targetLanguageName: langName,
                validation: validation
            )
            phase = .done(record)
            onComplete(record)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    // MARK: Speech

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task { await startRecording() }
        }
    }

    private func startRecording() async {
        guard await speech.requestPermissions() else {
            phase = .failed(
                AppError.speechPermissionDenied.localizedDescription
            )
            return
        }
        do {
            try speech.start { [weak self] text, isFinal in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if !text.isEmpty { self.inputText = text }
                    if isFinal { self.stopRecording() }
                }
            }
            isRecording = true
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func stopRecording() {
        speech.stop()
        isRecording = false
    }

    func loadLanguages() async {
        let languages = await languageService.supportedLanguages()
        if !languages.isEmpty { availableLanguages = languages }
    }

    func select(_ language: AppLanguage) {
        guard language != targetLanguage else { return }
        targetLanguage = language
        UserDefaults.standard.set(language.id, forKey: Self.languageKey)
        configuration = nil  // forces a fresh session with the new target
        phase = .idle
    }
}
