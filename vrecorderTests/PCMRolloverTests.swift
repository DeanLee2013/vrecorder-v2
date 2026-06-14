//  PCMRolloverTests.swift
//  Purpose: Bounded ring behavior for the VAD rotation rollover (bug #3).

import AVFoundation
import Testing
@testable import vrecorder

@Suite("PCMRollover")
struct PCMRolloverTests {
    private func buffer(_ tag: Float) -> AVAudioPCMBuffer {
        let fmt = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 1)!
        buf.frameLength = 1
        buf.floatChannelData![0][0] = tag   // tag so we can assert order
        return buf
    }

    @Test func keepsAtMostCapBuffersDroppingOldest() {
        let r = PCMRollover(cap: 3)
        for i in 0..<5 { r.add(buffer(Float(i))) }
        #expect(r.count == 3)
        let drained = r.drain()
        // Oldest (0,1) dropped; newest 3 retained in order 2,3,4.
        #expect(drained.map { $0.floatChannelData![0][0] } == [2, 3, 4])
    }

    @Test func drainResetsAndIsOrdered() {
        let r = PCMRollover(cap: 8)
        r.add(buffer(10)); r.add(buffer(20))
        #expect(r.drain().map { $0.floatChannelData![0][0] } == [10, 20])
        #expect(r.isEmpty)
        #expect(r.drain().isEmpty)   // draining empty is safe
    }

    @Test func zeroCapDropsEverything() {
        let r = PCMRollover(cap: 0)
        r.add(buffer(1)); r.add(buffer(2))
        #expect(r.isEmpty)
    }
}
