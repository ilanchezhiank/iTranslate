//
//  ValidationService.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import FoundationModels

nonisolated protocol ValidationServicing {
    func validate(original: String, translated: String, targetLanguage: String)
        async throws -> ValidationResult
}

/// Uses the on-device Foundation Model to sanity-check a translation.
nonisolated struct ValidationService: ValidationServicing {
    func validate(original: String, translated: String, targetLanguage: String)
        async throws -> ValidationResult
    {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw AppError.modelUnavailable(
                String(describing: model.availability)
            )
        }

        let session = LanguageModelSession(
            instructions: """
                You are a professional translation reviewer. Compare an original text with its \
                \(targetLanguage) translation and judge accuracy, tone and grammar. Be concise.
                """
        )

        let prompt = """
            Original: \(original)
            \(targetLanguage) translation: \(translated)
            """
        return try await session.respond(
            to: prompt,
            generating: ValidationResult.self
        ).content
    }
}
