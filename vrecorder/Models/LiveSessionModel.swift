//  LiveSessionModel.swift
//  Purpose: Observable session state for the live-interpretation screen. Runs the
//  STT→translate→display pipeline (or a no-network demo simulator). Correctness
//  guards: a session-generation token invalidates every stale async path on
//  stop/restart (#3); translation tasks are owned, cancelled on stop, and
//  committed in source order (#4); audio-session interruptions stop the session
//  (#5); teardown always deactivates the audio session (#6). rules/50 §2-4.

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

    /// Bumped on every start/stop; stale async work compares against it and bails.
    private var generation = 0
    private var sttTask: Task<Void, Never>?
    private var translationTasks: [Task<Void, Never>] = []
    private var demoTasks: [Task<Void, Never>] = []

    // Ordered translation commit: each final gets a seq; results commit in order.
    private var nextAssignSeq = 0
    private var nextCommitSeq = 0
    private var pendingTranslations: [Int: String] = [:]

    private let sourceLocale = Locale(identifier: "zh-CN")
    private let targetLocale = Locale(identifier: "en-US")

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
    var showPrompt: Bool { listening && partyA.allSatisfy { $0.status == .history } }

    func toggle() { listening ? stop() : start() }
    func clearError() { errorMessage = nil }

    /// Authoritative teardown. Bumps generation so any in-flight async path bails,
    /// cancels all owned tasks, releases the audio session. Safe to call repeatedly.
    func stop() {
        generation += 1
        listening = false
        recognizer?.stop()
        sttTask?.cancel(); sttTask = nil
        translationTasks.forEach { $0.cancel() }; translationTasks.removeAll()
        demoTasks.forEach { $0.cancel() }; demoTasks.removeAll()
        pendingTranslations.removeAll()
        audio?.deactivate()
    }

    // MARK: - Event ingestion

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
        generation += 1
        let gen = generation
        nextAssignSeq = 0; nextCommitSeq = 0; pendingTranslations.removeAll()
        listening = true
        audio?.onEvent = { [weak self] event in
            switch event {
            case .interruptionBegan, .routeLost: self?.stop()
            case .interruptionEnded: break        // require an explicit re-tap to resume
            }
        }
        sttTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await AppleSpeechRecognizer.requestAuthorization()
                guard gen == self.generation, !Task.isCancelled else { return }
                try self.audio?.activate()
                guard gen == self.generation, !Task.isCancelled else { self.audio?.deactivate(); return }
                let stream = try recognizer.start(locale: self.sourceLocale)
                for try await event in stream {
                    guard gen == self.generation else { break }
                    self.handle(event)
                }
            } catch {
                self.fail(error, gen: gen)
            }
            if gen == self.generation { self.stop() }   // normal completion → full teardown
        }
    }

    private func handle(_ event: TranscriptEvent) {
        switch event {
        case .partial(let t):
            pushA(.init(status: .partial, text: t))
        case .final(let t):
            pushA(.init(status: .final, text: t))
            translate(t, gen: generation, seq: nextAssignSeq)
            nextAssignSeq += 1
        }
    }

    private func translate(_ chinese: String, gen: Int, seq: Int) {
        guard let translator else { return }
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let english = try await translator.translate(chinese, from: sourceLocale, to: targetLocale)
                guard gen == self.generation, !Task.isCancelled else { return }
                self.commit(english, seq: seq)
            } catch {
                guard gen == self.generation, !Task.isCancelled else { return }
                self.fail(error, gen: gen)
            }
        }
        translationTasks.append(task)
    }

    /// Commit translations in source order so out-of-order completions don't
    /// scramble the counterpart panel.
    private func commit(_ english: String, seq: Int) {
        pendingTranslations[seq] = english
        while let text = pendingTranslations[nextCommitSeq] {
            if !text.isEmpty { pushB(.init(status: .final, text: text)) }
            pendingTranslations[nextCommitSeq] = nil
            nextCommitSeq += 1
        }
    }

    private func fail(_ error: Error, gen: Int) {
        guard gen == generation else { return }
        errorMessage = Self.message(for: error)
        stop()
    }

    static func message(for error: Error) -> String {
        switch error {
        case PipelineError.offline:               return "网络不可用，请检查连接"
        case PipelineError.timeout:               return "翻译超时，请重试"
        case PipelineError.rateLimited:           return "请求过于频繁，请稍后再试"
        case PipelineError.micPermissionDenied:   return "需要麦克风权限，请在设置中开启"
        case PipelineError.speechPermissionDenied: return "需要语音识别权限，请在设置中开启"
        case PipelineError.missingAPIKey:         return "未配置 API 密钥"
        case PipelineError.recognizerUnavailable: return "当前语言的语音识别不可用"
        case PipelineError.providerError(let m):  return "翻译服务错误：\(m)"
        default:                                  return "发生未知错误"
        }
    }

    // MARK: - Demo simulator (no network — course-demo fallback)

    private func startDemo() {
        generation += 1
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
