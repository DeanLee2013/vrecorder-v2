//  RecognitionEventCoalescerTests.swift
//  Purpose: Event-aware buffering (bug #2): partials coalesce to the latest;
//  finals are NEVER dropped, even under a delayed/bursty consumer.

import Testing
@testable import vrecorder

@Suite("RecognitionEventCoalescer")
struct RecognitionEventCoalescerTests {
    @Test func partialsCoalesceToLatest() {
        let c = RecognitionEventCoalescer()
        c.push(.partial("你"))
        c.push(.partial("你好"))
        c.push(.partial("你好吗"))
        #expect(c.drain() == [.partial("你好吗")])   // only the latest partial survives
        #expect(c.isEmpty)
    }

    @Test func delayedConsumerNeverDropsFinals() {
        let c = RecognitionEventCoalescer()
        // A burst arrives before the consumer drains: many partials + several finals
        // interleaved. The High bug was that a bounded policy could evict a final.
        c.push(.partial("a"))
        c.push(.final("第一句。"))
        c.push(.partial("b"))
        c.push(.partial("bb"))
        c.push(.final("第二句。"))
        c.push(.partial("c"))
        c.push(.final("第三句。"))
        c.push(.partial("尾巴"))
        let drained = c.drain()
        // Every final present, in order; only the latest trailing partial kept.
        #expect(drained == [.final("第一句。"), .final("第二句。"), .final("第三句。"), .partial("尾巴")])
    }

    @Test func finalClearsPendingPartial() {
        let c = RecognitionEventCoalescer()
        c.push(.partial("半句"))
        c.push(.final("半句完整了。"))
        #expect(c.drain() == [.final("半句完整了。")])   // the partial became the final
    }

    @Test func drainEmptyIsSafe() {
        let c = RecognitionEventCoalescer()
        #expect(c.drain().isEmpty)
        #expect(c.isEmpty)
    }
}
