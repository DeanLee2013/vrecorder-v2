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
    @State private var env = AppEnvironment(uiTesting: Self.isUITesting)

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
                .debugBridge(env.session)   // DEBUG-only vrecorder-debug:// seam
        }
    }

    /// DEBUG-only: Release never reads the launch-arg seam (audit-WI2 #1).
    private static var isUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
        #else
        false
        #endif
    }
}
