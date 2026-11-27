//
//  TranslationService.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import Translation

nonisolated protocol TranslationServicing {
    func translate(_ text: String, using session: TranslationSession)
        async throws -> String
}

/// Wraps Apple's on-device Translation framework.
nonisolated struct TranslationService: TranslationServicing {
    func translate(_ text: String, using session: TranslationSession)
        async throws -> String
    {
        try await session.translate(text).targetText
    }
}
