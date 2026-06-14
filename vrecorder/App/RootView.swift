//  RootView.swift
//  Purpose: Top-level navigation. Live IS the home screen; the gear pushes
//  Settings and the chevron returns (session state is retained). design/README.md.

import SwiftUI

struct RootView: View {
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase
    private let env = AppEnvironment()

    var body: some View {
        ZStack {
            LiveScreen(session: env.session, onSettings: { showSettings = true })

            if showSettings {
                SettingsScreen(onBack: { showSettings = false }, store: env.keyStore)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.42), value: showSettings)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            // Don't leave the mic + audio session live in the background
            // (audit-4 #6) — tear down explicitly instead of relying on the OS.
            if phase == .background { env.session.stop() }
        }
    }
}
