//
//  RootTabView.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Translate", systemImage: "character.bubble") {
                TranslateView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
        }
    }
}
