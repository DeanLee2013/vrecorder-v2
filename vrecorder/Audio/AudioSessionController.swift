//  AudioSessionController.swift
//  Purpose: Single owner of AVAudioSession config + interruption / route-change
//  handling. The pipeline pauses on interruption (call, Siri, alarm) and the
//  session is centralized here so no other type touches AVAudioSession.
//  See rules/50 §4 Audio Session.

import AVFoundation

@MainActor
final class AudioSessionController {
    private let session = AVAudioSession.sharedInstance()
    var onInterruption: (() -> Void)?

    func activate() throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: session)
    }

    func deactivate() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: session)
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began { onInterruption?() }
    }
}
