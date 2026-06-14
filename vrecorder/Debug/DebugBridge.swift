//  DebugBridge.swift
//  Purpose: DEBUG-only verification seam (feature #6 WI-3). Parses
//  `vrecorder-debug://` URLs (delivered via XCUITest's XCUIApplication.open) and
//  drives LiveSessionModel through the WI-1 fixture API, so UI tests can reach
//  deterministic transcript/listening states without a mic. File-scope DEBUG
//  gated (rule 50 §7); the `.debugBridge` modifier is a no-op in Release.

import SwiftUI

#if DEBUG
@MainActor
struct DebugBridge {
    let session: LiveSessionModel
    init(_ session: LiveSessionModel) { self.session = session }

    /// `vrecorder-debug://inject?a=<text>&b=<text>&listening=true`
    /// `vrecorder-debug://reset`. Anything else is a no-op.
    func handle(_ url: URL) {
        guard url.scheme == "vrecorder-debug",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        switch comps.host {
        case "inject":
            let items = comps.queryItems ?? []
            func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
            let a = value("a").map { [TranscriptLine(status: .final, text: $0)] } ?? []
            let b = value("b").map { [TranscriptLine(status: .final, text: $0)] } ?? []
            let listening = value("listening") == "true"   // strict: only "true"
            session.installFixture(a: a, b: b, listening: listening)
        case "reset":
            session.resetTranscripts()
        default:
            break
        }
    }
}

extension View {
    /// Wire the `vrecorder-debug://` URL scheme to the DebugBridge (DEBUG only).
    func debugBridge(_ session: LiveSessionModel) -> some View {
        onOpenURL { url in DebugBridge(session).handle(url) }
    }
}
#else
extension View {
    /// No-op in Release — the debug URL scheme is not registered there.
    func debugBridge(_ session: LiveSessionModel) -> some View { self }
}
#endif
