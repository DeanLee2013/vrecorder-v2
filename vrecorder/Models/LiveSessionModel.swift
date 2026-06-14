//  LiveSessionModel.swift
//  Purpose: Observable session state for the live-interpretation screen. Runs the
//  STT→translate→display pipeline (or a no-network demo simulator).
//  Correctness guards: a session-generation token invalidates stale async paths
//  on stop/restart (#3); translations run through ONE bounded sequential queue so
//  tasks don't accumulate and results commit in source order (#4, audit-2 High);
//  audio interruptions stop the session (#5); teardown always deactivates the
//  audio session (#6). Engines are referenced via protocols so they're mockable.
//  rules/50 §2-4.

import SwiftUI

@MainActor
@Observable
final class LiveSessionModel {
    private(set) var listening = false
    private(set) var partyA: [TranscriptLine]   // you (中文)
    private(set) var partyB: [TranscriptLine]   // counterpart (English)
    private(set) var errorMessage: String?

    private let maxLines = 3
    private let recognizer: (any SpeechRecognizing)?
    private let translator: (any TranslationEngine)?
    private let audio: AudioSessionController?

    /// Bumped on every start/stop; stale async work compares against it and bails.
    private var generation = 0
    private var sttTask: Task<Void, Never>?
    private var translationConsumer: Task<Void, Never>?
    private var finalsContinuation: AsyncStream<String>.Continuation?
    private var demoTask: Task<Void, Never>?

    private let sourceLocale = Locale(identifier: "zh-CN")
    private let targetLocale = Locale(identifier: "en-US")

    init(recognizer: (any SpeechRecognizing)? = nil,
         translator: (any TranslationEngine)? = nil,
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
    /// cancels owned tasks, closes the translation queue, releases the audio
    /// session. Safe to call repeatedly.
    func stop() {
        generation += 1
        listening = false
        recognizer?.stop()
        sttTask?.cancel(); sttTask = nil
        finalsContinuation?.finish(); finalsContinuation = nil
        translationConsumer?.cancel(); translationConsumer = nil
        demoTask?.cancel(); demoTask = nil
        audio?.deactivate()
    }

    // MARK: - Event ingestion

    /// Push a line into a panel. If the active (trailing) line is a partial, the
    /// incoming line continues that same segment — reuse its id so SwiftUI
    /// animates partial→final in place rather than as a remove/insert (audit Low).
    private func push(into lines: inout [TranscriptLine], _ line: TranscriptLine) {
        var incoming = line
        var kept = lines
        if let last = kept.last, last.status == .partial {
            incoming = TranscriptLine(id: last.id, status: line.status, text: line.text)
            kept.removeLast()
        }
        kept = kept.map { l -> TranscriptLine in
            var l = l; if l.status == .final { l.status = .history }; return l
        }
        if kept.count > maxLines - 1 { kept.removeFirst(kept.count - (maxLines - 1)) }
        kept.append(incoming)
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
        listening = true
        startTranslationQueue(gen: gen)
        audio?.onEvent = { [weak self] event in
            switch event {
            case .interruptionBegan, .routeLost: self?.stop()
            case .interruptionEnded: break        // require an explicit re-tap to resume
            }
        }
        sttTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await recognizer.requestAuthorization()
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
            if gen == self.generation { self.stop() }
        }
    }

    private func handle(_ event: TranscriptEvent) {
        switch event {
        case .partial(let t):
            pushA(.init(status: .partial, text: t))
        case .final(let t):
            pushA(.init(status: .final, text: t))
            finalsContinuation?.yield(t)          // enqueue for ordered translation
        }
    }

    /// One consumer translates finals sequentially (bounded — no task pile-up)
    /// and commits in source order.
    private func startTranslationQueue(gen: Int) {
        guard let translator else { return }
        // Bounded buffer: if translation falls behind speech, drop the oldest
        // pending finals deterministically rather than growing unboundedly
        // (audit-3 #3). A live interpreter values latest speech over backlog.
        let (stream, cont) = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingNewest(8))
        finalsContinuation = cont
        translationConsumer = Task { [weak self] in
            for await chinese in stream {
                guard let self, gen == self.generation, !Task.isCancelled else { continue }
                do {
                    let english = try await translator.translate(chinese, from: self.sourceLocale, to: self.targetLocale)
                    guard gen == self.generation, !Task.isCancelled else { continue }
                    if !english.isEmpty { self.pushB(.init(status: .final, text: english)) }
                } catch {
                    guard gen == self.generation else { continue }
                    self.fail(error, gen: gen)
                }
            }
        }
    }

    private func fail(_ error: Error, gen: Int) {
        guard gen == generation else { return }
        errorMessage = Self.message(for: error)
        stop()
    }

    static func message(for error: Error) -> String {
        switch error {
        case PipelineError.offline:                return "网络不可用，请检查连接"
        case PipelineError.timeout:                return "翻译超时，请重试"
        case PipelineError.rateLimited:            return "请求过于频繁，请稍后再试"
        case PipelineError.micPermissionDenied:    return "需要麦克风权限，请在设置中开启"
        case PipelineError.speechPermissionDenied: return "需要语音识别权限，请在设置中开启"
        case PipelineError.missingAPIKey:          return "未配置 API 密钥"
        case PipelineError.invalidAPIKey:          return "API 密钥无效或已失效，请在设置中更新"
        case PipelineError.recognizerUnavailable:  return "当前语言的语音识别不可用"
        case PipelineError.recognitionFailed:      return "语音识别失败，请重试"
        case PipelineError.providerError(let m):   return "翻译服务错误：\(m)"
        default:                                   return "发生未知错误"
        }
    }

    // MARK: - Demo simulator (no network — course-demo fallback)

    private func startDemo() {
        generation += 1
        let gen = generation
        listening = true
        let steps: [(UInt64, Bool, TranscriptLine)] = [
            (500,  true,  .init(status: .partial, text: "重庆火锅很辣，但是…")),
            (500,  false, .init(status: .partial, text: "Chongqing hot pot is spicy, but…")),
            (1000, true,  .init(status: .final,   text: "重庆火锅很辣，但是很好吃！")),
            (600,  false, .init(status: .final,   text: "Chongqing hot pot is spicy, but delicious!")),
        ]
        demoTask = Task { [weak self] in
            for (ms, isA, line) in steps {
                do { try await Task.sleep(nanoseconds: ms * 1_000_000) }
                catch { return }                              // cancelled → stop mutating
                guard let self, gen == self.generation, !Task.isCancelled else { return }
                isA ? self.pushA(line) : self.pushB(line)
            }
            if let self, gen == self.generation { self.listening = false }
        }
    }
}
