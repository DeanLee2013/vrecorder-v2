//  RootView.swift
//  Purpose: Top-level navigation. Live IS the home screen; the gear pushes
//  Settings and the chevron returns (session state is retained). design/README.md.

import SwiftUI

struct RootView: View {
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase
    // @State so SwiftUI keeps ONE environment for this view's identity — a plain
    // stored property is rebuilt on each RootView init, which let scene-phase
    // teardown stop() a different session than the screen holds (audit-G4r2 #2).
    @State private var env = AppEnvironment()

    var body: some View {
        ZStack {
            // Color scheme is per-surface (audit-G4 #5): the live stage is dark,
            // Settings + its key-entry sheet are light — forcing dark globally gave
            // the light sheet low-contrast system chrome.
            LiveScreen(session: env.session, onSettings: { showSettings = true })
                .preferredColorScheme(.dark)

            if showSettings {
                SettingsScreen(onBack: { showSettings = false }, store: env.keyStore)
                    .preferredColorScheme(.light)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.42), value: showSettings)
        .onChange(of: scenePhase) { _, phase in
            // Don't leave the mic + audio session live in the background
            // (audit-4 #6) — tear down explicitly instead of relying on the OS.
            if phase == .background { env.session.stop() }
        }
    }
}
