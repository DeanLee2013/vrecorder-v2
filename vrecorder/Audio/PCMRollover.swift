//  PCMRollover.swift
//  Purpose: Bounded ring of recent PCM buffers captured during the gap between a
//  recognizer's endAudio() and the next request being installed (bug #3 / docs
//  bug #1). When the new request arrives, the ring is drained and replayed into
//  it so the START of the next utterance is not silently dropped.

import AVFoundation

/// Not thread-safe on its own — `AudioTapBridge` guards it with its lock.
final class PCMRollover {
    private var buffers: [AVAudioPCMBuffer] = []
    private let cap: Int

    /// `cap` = max buffers retained (≈ cap × tap-buffer duration, ~0.5s at 24 ×
    /// 1024-frame @ 48 kHz). A realistic rotation gap (the async final→startSegment
    /// hop) is a few buffers, well under cap, so nothing is dropped and the next
    /// utterance's onset is preserved.
    ///
    /// **Known limitation** (bug #1 / feature #4): if rotation stalls for longer
    /// than `cap` while the user keeps speaking, the oldest buffers (early onset)
    /// are dropped and that span can still truncate. The robust fix is a dedicated
    /// VAD/segmentation stage that rotates with no gap (tracked as feature #4); the
    /// ring is the pragmatic mitigation for the common case.
    init(cap: Int) { self.cap = max(0, cap) }

    var count: Int { buffers.count }
    var isEmpty: Bool { buffers.isEmpty }

    func add(_ buffer: AVAudioPCMBuffer) {
        guard cap > 0 else { return }
        buffers.append(buffer)
        if buffers.count > cap { buffers.removeFirst(buffers.count - cap) }
    }

    /// Return the retained buffers in arrival order and reset the ring.
    func drain() -> [AVAudioPCMBuffer] {
        defer { buffers.removeAll() }
        return buffers
    }
}
