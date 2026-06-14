//  VRecorderApp.swift
//  Purpose: App entry point. Launches straight into the live-interpretation
//  screen (no onboarding for the MVP). design/README.md.

import SwiftUI

@main
struct VRecorderApp: App {
    // The App owns the single environment via @State (lifted from RootView so the
    // DebugBridge/WI-3 can share the same session) — preserves the stable-identity
    // ownership that fixes scene-phase teardown (audit-G4r2 #2). UI-testing mode is
    // selected from the launch arguments.
    @State private var env = AppEnvironment(
        uiTesting: ProcessInfo.processInfo.arguments.contains("-uiTesting"))

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
        }
    }
}
