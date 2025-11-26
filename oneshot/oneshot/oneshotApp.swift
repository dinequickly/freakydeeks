//
//  oneshotApp.swift
//  oneshot
//
//  Created by Maxwell Moroz on 11/26/25.
//

import SwiftUI

@main
struct oneshotApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
