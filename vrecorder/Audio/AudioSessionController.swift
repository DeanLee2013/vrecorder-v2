//  AudioSessionController.swift
//  Purpose: Single owner of AVAudioSession config + interruption / route-change
//  handling. Exposes typed events the session model wires into its lifecycle
//  (pause on interruption-began / device loss; the model decides resume policy).
//  `deactivate` always releases the session so other apps stop being ducked.
//  See rules/50 §4 and DIMENSIONS-ios.md §2.

import AVFoundation

@MainActor
final class AudioSessionController {
    enum Event {
        case interruptionBegan
        case interruptionEnded(shouldResume: Bool)
        case routeLost          // e.g. AirPods disconnected — input path changed
    }

    private let session = AVAudioSession.sharedInstance()
    /// Set by the owner before `activate()`. Delivered on the main actor.
    var onEvent: ((Event) -> Void)?
    private var active = false

    func activate() throws {
        try session.setCategory(.playAndRecord, mode: .measurement,
                                options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        active = true
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification, object: session)
        nc.addObserver(self, selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification, object: session)
    }

    /// Idempotent: safe to call on every termination path.
    func deactivate() {
        NotificationCenter.default.removeObserver(self)
        guard active else { return }
        active = false
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            onEvent?(.interruptionBegan)
        case .ended:
            let opts = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt).map {
                AVAudioSession.InterruptionOptions(rawValue: $0)
            } ?? []
            onEvent?(.interruptionEnded(shouldResume: opts.contains(.shouldResume)))
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
        if reason == .oldDeviceUnavailable { onEvent?(.routeLost) }
    }
}
