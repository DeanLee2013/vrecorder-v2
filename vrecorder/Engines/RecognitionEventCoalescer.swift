//  RecognitionEventCoalescer.swift
//  Purpose: Event-aware bounded buffer between the off-main recognition callback
//  and the stream consumer (bug #2 / GH #4). Partials are REPLACEABLE so only the
//  latest is kept (coalesced); finals are QUEUED and never dropped. A bounded
//  buffering policy could silently evict an unconsumed `.final`; this can't.
//  One pump task drains it, so frequent partials don't spawn per-callback Tasks.

import Foundation

final class RecognitionEventCoalescer: @unchecked Sendable {
    private let lock = NSLock()
    private var latestPartial: String?
    private var finals: [String] = []          // FIFO; finals are rare, never dropped

    private let signal: AsyncStream<Void>
    private let signalContinuation: AsyncStream<Void>.Continuation

    init() {
        (signal, signalContinuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
    }

    /// Push a recognition event. A partial replaces any pending partial; a final
    /// is queued (and clears the pending partial it finalized). Wakes the pump.
    func push(_ event: TranscriptEvent) {
        lock.lock()
        switch event {
        case .partial(let text):
            latestPartial = text
        case .final(let text):
            finals.append(text)
            latestPartial = nil
        }
        lock.unlock()
        signalContinuation.yield(())
    }

    /// Drain everything currently buffered in emit order: queued finals (FIFO)
    /// then the single latest partial. Resets the buffer.
    func drain() -> [TranscriptEvent] {
        lock.lock(); defer { lock.unlock() }
        var out: [TranscriptEvent] = finals.map { .final($0) }
        finals.removeAll()
        if let partial = latestPartial { out.append(.partial(partial)); latestPartial = nil }
        return out
    }

    var isEmpty: Bool { lock.withLock { finals.isEmpty && latestPartial == nil } }

    /// Wake-up signal for the pump (coalesced to 1 — multiple pushes between
    /// drains wake the pump once).
    var wakeups: AsyncStream<Void> { signal }

    /// End the wake-up stream so the pump loop exits.
    func finish() { signalContinuation.finish() }
}
