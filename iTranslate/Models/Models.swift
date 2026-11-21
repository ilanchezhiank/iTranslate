//
//  Models.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import Foundation
import FoundationModels

/// Structured output produced by the on-device language model.
@Generable
struct ValidationResult: Equatable {
    @Guide(description: "True if the translation faithfully conveys the meaning of the original text")
    var isAccurate: Bool

    @Guide(description: "Quality score from 1 (poor) to 10 (perfect)", .range(1...10))
    var score: Int

    @Guide(description: "One or two sentences explaining the verdict")
    var feedback: String

    @Guide(description: "A better translation if the given one has issues, otherwise empty")
    var suggestedCorrection: String
}

struct AppLanguage: Identifiable, Hashable {
    let language: Locale.Language
    // maximalIdentifier is unique (e.g. distinguishes zh-Hans / zh-Hant) and round-trips for persistence
    var id: String { language.maximalIdentifier }
    var name: String {
        Locale.current.localizedString(forIdentifier: language.minimalIdentifier) ?? language.minimalIdentifier
    }

    init(_ language: Locale.Language) { self.language = language }

    static func == (l: Self, r: Self) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct TranslationRecord: Identifiable, Equatable {
    let id = UUID()
    let original: String
    let translated: String
    let targetLanguageName: String
    let validation: ValidationResult?
    let date = Date()
}

enum AppError: LocalizedError {
    case emptyInput
    case modelUnavailable(String)
    case speechPermissionDenied

    var errorDescription: String? {
        switch self {
        case .emptyInput: "Please enter or dictate some text first."
        case .modelUnavailable(let reason): "Apple Intelligence is unavailable: \(reason)"
        case .speechPermissionDenied: "Microphone or speech recognition permission was denied. Enable it in Settings."
        }
    }
}

