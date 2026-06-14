//  RootView.swift
//  Purpose: Top-level navigation. Live IS the home screen; the gear pushes
//  Settings and the chevron returns (session state is retained). design/README.md.

import SwiftUI

struct RootView: View {
    @State private var showSettings = false
    private let env = AppEnvironment()

    var body: some View {
        ZStack {
            LiveScreen(session: env.session, onSettings: { showSettings = true })

            if showSettings {
                SettingsScreen(onBack: { showSettings = false })
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.42), value: showSettings)
        .preferredColorScheme(.dark)
    }
}
