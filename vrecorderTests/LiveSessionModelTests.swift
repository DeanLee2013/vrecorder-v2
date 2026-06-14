//  LiveSessionModelTests.swift
//  Purpose: Smoke tests for the partial → final → history transcript lifecycle.

import Testing
@testable import vrecorder

@MainActor
@Suite("LiveSessionModel")
struct LiveSessionModelTests {
    @Test func partialIsReplacedNotAppended() {
        let m = LiveSessionModel()
        let before = m.partyA.count
        m.pushA(.init(status: .partial, text: "你好…"))
        m.pushA(.init(status: .partial, text: "你好吗…"))
        // Two partials in a row keep only one live line on top.
        #expect(m.partyA.count == before + 1)
        #expect(m.partyA.last?.text == "你好吗…")
        #expect(m.partyA.last?.status == .partial)
    }

    @Test func finalDemotesPreviousLinesToHistory() {
        let m = LiveSessionModel()
        m.pushA(.init(status: .final, text: "第一句。"))
        m.pushA(.init(status: .final, text: "第二句。"))
        // The earlier final becomes history once a newer line lands.
        #expect(m.partyA.dropLast().allSatisfy { $0.status == .history })
        #expect(m.partyA.last?.status == .final)
    }

    @Test func panelKeepsAtMostThreeLines() {
        let m = LiveSessionModel()
        for i in 0..<6 { m.pushA(.init(status: .final, text: "句\(i)")) }
        #expect(m.partyA.count <= 3)
    }

    @Test func micAndSpeechDenialHaveDistinctMessages() {
        let mic = LiveSessionModel.message(for: PipelineError.micPermissionDenied)
        let speech = LiveSessionModel.message(for: PipelineError.speechPermissionDenied)
        #expect(mic != speech)
        #expect(mic.contains("麦克风"))
        #expect(speech.contains("语音识别"))
    }

    @Test func timeoutIsNotLabeledOffline() {
        let timeout = LiveSessionModel.message(for: PipelineError.timeout)
        let offline = LiveSessionModel.message(for: PipelineError.offline)
        #expect(timeout != offline)
        #expect(!timeout.contains("网络不可用"))
    }
}
