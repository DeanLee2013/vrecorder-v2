//  DebugBridgeTests.swift
//  Purpose: DEBUG-only — DebugBridge URL parsing drives the model fixture API
//  (feature #6 WI-3). Drives a LiveSessionModel directly; no UI, no URL scheme.

#if DEBUG
import Foundation
import Testing
@testable import vrecorder

@MainActor
@Suite("DebugBridge")
struct DebugBridgeTests {
    private func url(_ s: String) -> URL { URL(string: s)! }

    @Test func injectSeedsTranscript() {
        let m = LiveSessionModel()
        DebugBridge(m).handle(url("vrecorder-debug://inject?a=NIHAO&b=hello"))
        #expect(m.partyA.map(\.text) == ["NIHAO"])
        #expect(m.partyB.map(\.text) == ["hello"])
        #expect(!m.listening)
    }

    @Test func injectListeningTrueSetsListening() {
        let m = LiveSessionModel()
        DebugBridge(m).handle(url("vrecorder-debug://inject?a=x&listening=true"))
        #expect(m.listening)
    }

    @Test func injectListeningAbsentOrOtherIsIdle() {
        let m = LiveSessionModel()
        DebugBridge(m).handle(url("vrecorder-debug://inject?a=x&listening=yes"))  // not "true"
        #expect(!m.listening)
    }

    @Test func resetClears() {
        let m = LiveSessionModel()
        DebugBridge(m).handle(url("vrecorder-debug://inject?a=x&b=y"))
        DebugBridge(m).handle(url("vrecorder-debug://reset"))
        #expect(m.partyA.isEmpty)
        #expect(m.partyB.isEmpty)
    }

    @Test func malformedOrUnknownIsNoOp() {
        let m = LiveSessionModel()
        let before = m.partyA.map(\.text)
        DebugBridge(m).handle(url("vrecorder-debug://bogus"))
        DebugBridge(m).handle(url("https://example.com/inject?a=x"))   // wrong scheme
        #expect(m.partyA.map(\.text) == before)   // unchanged, no crash
    }
}
#endif
