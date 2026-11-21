//
//  HistoryViewModel.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import Foundation
import SwiftUI

@MainActor @Observable
final class HistoryViewModel {
    private(set) var records: [TranslationRecord] = []

    func add(_ record: TranslationRecord) { records.insert(record, at: 0) }
    func delete(at offsets: IndexSet) { records.remove(atOffsets: offsets) }
    func clear() { records.removeAll() }
}
