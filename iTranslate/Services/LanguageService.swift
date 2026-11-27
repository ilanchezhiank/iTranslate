//
//  LanguageService.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import Translation

nonisolated protocol LanguageServicing {
    func supportedLanguages() async -> [AppLanguage]
}

nonisolated struct LanguageService: LanguageServicing {
    func supportedLanguages() async -> [AppLanguage] {
        await LanguageAvailability().supportedLanguages
            .map(AppLanguage.init)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }
    }
}
