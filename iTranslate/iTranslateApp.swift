//
//  iTranslateApp.swift
//  iTranslate
//
//  Created by Ilanchezhian Kuppusamy on 05/10/26.
//

import SwiftUI

@main
struct iTranslateApp: App {
    @State private var history = HistoryViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(history)
        }
    }
}
