//
//  HistoryView.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import SwiftUI

struct HistoryView: View {
    @Environment(HistoryViewModel.self) private var history

    var body: some View {
        NavigationStack {
            Group {
                if history.records.isEmpty {
                    ContentUnavailableView("No translations yet", systemImage: "text.bubble",
                                           description: Text("Your translations will appear here."))
                } else {
                    List {
                        ForEach(history.records) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.original).foregroundStyle(.secondary)
                                Text(record.translated).font(.headline)
                                if let v = record.validation {
                                    Label("\(v.score)/10", systemImage: v.isAccurate ? "checkmark.seal" : "exclamationmark.triangle")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete(perform: history.delete)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !history.records.isEmpty { Button("Clear", role: .destructive, action: history.clear) }
            }
        }
    }
}
