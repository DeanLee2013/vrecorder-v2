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

    /// `cap` = max buffers retained (≈ cap × tap-buffer duration). Older buffers
    /// beyond the cap are dropped so the gap can't grow unbounded.
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
