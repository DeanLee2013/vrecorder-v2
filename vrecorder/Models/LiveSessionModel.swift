//  LiveSessionModel.swift
//  Purpose: Observable session state for the live-interpretation screen.
//  Drives both party panels through idle → listening → partial* → final → idle.
//  Two engines plug in via protocols: an on-device recognizer (中文 STT) and a
//  translation engine (中文→English). When no engines are injected it runs the
//  built-in demo simulator (course-demo fallback, no network). rules/50 §2-3.

import SwiftUI

@MainActor
@Observable
final class LiveSessionModel {
    private(set) var listening = false
    private(set) var partyA: [TranscriptLine]   // you (中文)
    private(set) var partyB: [TranscriptLine]   // counterpart (English)
    private(set) var errorMessage: String?

    private let maxLines = 3
    private let recognizer: AppleSpeechRecognizer?
    private let translator: TranslationEngine?
    private let audio: AudioSessionController?

    private var sttTask: Task<Void, Never>?
    private var demoTasks: [Task<Void, Never>] = []

    private let sourceLocale = Locale(identifier: "zh-CN")
    private let targetLocale = Locale(identifier: "en-US")

    /// Inject engines for the real pipeline; omit them for the demo simulator.
    init(recognizer: AppleSpeechRecognizer? = nil,
         translator: TranslationEngine? = nil,
         audio: AudioSessionController? = nil) {
        self.recognizer = recognizer
        self.translator = translator
        self.audio = audio
        partyA = [TranscriptLine(status: .history, text: "中国有很多美食。")]
        partyB = [TranscriptLine(status: .history, text: "There is a lot of delicious food in China.")]
    }

    private var hasPipeline: Bool { recognizer != nil && translator != nil }

    var showPrompt: Bool {
        listening && partyA.allSatisfy { $0.status == .history }
    }

    func toggle() {
        listening ? stop() : start()
    }

    func clearError() { errorMessage = nil }

    func stop() {
        listening = false
        recognizer?.stop()
        sttTask?.cancel(); sttTask = nil
        demoTasks.forEach { $0.cancel() }; demoTasks.removeAll()
        audio?.deactivate()
    }

    // MARK: - Event ingestion

    /// `partial` replaces the previous partial; anything else demotes prior
    /// lines to history before appending. Keeps at most `maxLines` per panel.
    private func push(into lines: inout [TranscriptLine], _ line: TranscriptLine) {
        var kept = lines
            .filter { $0.status != .partial }
            .map { l -> TranscriptLine in
                var l = l; if l.status == .final { l.status = .history }; return l
            }
        if kept.count > maxLines - 1 { kept.removeFirst(kept.count - (maxLines - 1)) }
        kept.append(line)
        lines = kept
    }

    func pushA(_ line: TranscriptLine) { push(into: &partyA, line) }
    func pushB(_ line: TranscriptLine) { push(into: &partyB, line) }

    // MARK: - Real pipeline

    private func start() {
        errorMessage = nil
        guard hasPipeline, let recognizer else { startDemo(); return }
        listening = true
        sttTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await AppleSpeechRecognizer.requestAuthorization()
                try self.audio?.activate()
                let stream = try recognizer.start(locale: self.sourceLocale)
                for try await event in stream {
                    self.handle(event)
                }
            } catch {
                self.fail(error)
            }
            self.listening = false
        }
    }

    private func handle(_ event: TranscriptEvent) {
        switch event {
        case .partial(let t):
            pushA(.init(status: .partial, text: t))
        case .final(let t):
            pushA(.init(status: .final, text: t))
            translate(t)
        }
    }

    private func translate(_ chinese: String) {
        guard let translator else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let english = try await translator.translate(chinese, from: sourceLocale, to: targetLocale)
                guard !english.isEmpty else { return }
                self.pushB(.init(status: .final, text: english))
            } catch {
                self.fail(error)
            }
        }
    }

    private func fail(_ error: Error) {
        errorMessage = Self.message(for: error)
        stop()
    }

    static func message(for error: Error) -> String {
        switch error {
        case PipelineError.offline:          return "网络不可用，请检查连接"
        case PipelineError.timeout:          return "翻译超时，请重试"
        case PipelineError.rateLimited:      return "请求过于频繁，请稍后再试"
        case PipelineError.permissionDenied: return "需要麦克风与语音识别权限"
        case PipelineError.missingAPIKey:    return "未配置 API 密钥"
        case PipelineError.providerError(let m): return "翻译服务错误：\(m)"
        default:                             return "发生未知错误"
        }
    }

    // MARK: - Demo simulator (no network — course-demo fallback)

    private func startDemo() {
        listening = true
        let pa = "重庆火锅很辣，但是…"
        let fa = "重庆火锅很辣，但是很好吃！"
        let pb = "Chongqing hot pot is spicy, but…"
        let fb = "Chongqing hot pot is spicy, but delicious!"
        demoTasks.append(Task { [weak self] in
            await self?.delay(ms: 500);  self?.pushA(.init(status: .partial, text: pa))
            await self?.delay(ms: 500);  self?.pushB(.init(status: .partial, text: pb))
            await self?.delay(ms: 1000); self?.pushA(.init(status: .final, text: fa))
            await self?.delay(ms: 600);  self?.pushB(.init(status: .final, text: fb))
            self?.listening = false
        })
    }

    private func delay(ms: UInt64) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }
}
