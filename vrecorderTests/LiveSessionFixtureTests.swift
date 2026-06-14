//  LiveSessionFixtureTests.swift
//  Purpose: DEBUG-only fixture seam (feature #6 WI-1) — installFixture stops any
//  active session and atomically installs a deterministic transcript/listening
//  state; resetTranscripts clears. Used by the DebugBridge so UI tests can reach
//  states without a mic.

#if DEBUG
import Testing
@testable import vrecorder

@MainActor
@Suite("LiveSessionModel fixtures")
struct LiveSessionFixtureTests {
    private let a = [TranscriptLine(status: .final, text: "中文固定")]
    private let b = [TranscriptLine(status: .final, text: "English fixed")]

    @Test func installFixtureStopsActiveSessionAndReplaces() {
        let m = LiveSessionModel()          // demo-mode (no engines)
        m.toggle()                          // start the demo → listening
        #expect(m.listening)
        m.installFixture(a: a, b: b)        // stops the demo, installs the fixture
        #expect(!m.listening)               // demo session stopped
        #expect(m.partyA.map(\.text) == ["中文固定"])
        #expect(m.partyB.map(\.text) == ["English fixed"])
    }

    @Test func installFixtureListeningSetsDeterministicActiveState() {
        let m = LiveSessionModel()
        m.installFixture(a: a, b: b, listening: true)
        #expect(m.listening)                // active state without a recognizer
        #expect(m.partyA.map(\.text) == ["中文固定"])
    }

    @Test func resetClears() {
        let m = LiveSessionModel()
        m.installFixture(a: a, b: b, listening: true)
        m.resetTranscripts()
        #expect(!m.listening)
        #expect(m.partyA.isEmpty)
        #expect(m.partyB.isEmpty)
    }
}
#endif
