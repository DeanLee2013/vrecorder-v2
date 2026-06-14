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
    /// Set by the owner before `activate()`. Always delivered on the main actor.
    var onEvent: ((Event) -> Void)?
    private var active = false
    private var tokens: [NSObjectProtocol] = []

    func activate() throws {
        try session.setCategory(.playAndRecord, mode: .measurement,
                                options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        active = true

        // Block observers pinned to .main: notifications post on arbitrary
        // threads; routing them through the main queue keeps onEvent (which
        // mutates @MainActor state) on the main actor (audit-G4r2 #1).
        let nc = NotificationCenter.default
        tokens.append(nc.addObserver(forName: AVAudioSession.interruptionNotification,
                                     object: session, queue: .main) { [weak self] note in
            // Parse Sendable primitives here; only those cross the actor hop
            // (Notification itself is non-Sendable).
            let typeRaw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            MainActor.assumeIsolated { self?.handleInterruption(typeRaw: typeRaw, optsRaw: optsRaw) }
        })
        tokens.append(nc.addObserver(forName: AVAudioSession.routeChangeNotification,
                                     object: session, queue: .main) { [weak self] note in
            let reasonRaw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            MainActor.assumeIsolated { self?.handleRouteChange(reasonRaw: reasonRaw) }
        })
    }

    /// Idempotent: safe to call on every termination path. Marks inactive only
    /// after a successful deactivation so a failure preserves retry (audit-G4r2 #3).
    func deactivate() {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
        tokens.removeAll()
        guard active else { return }
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            active = false
        } catch {
            // Stay active so a later deactivate() retries; don't strand other
            // apps ducked silently.
            Log.audio.error("AVAudioSession deactivate failed: \(error.localizedDescription)")
        }
    }

    private func handleInterruption(typeRaw: UInt?, optsRaw: UInt?) {
        guard let typeRaw, let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
        switch type {
        case .began:
            onEvent?(.interruptionBegan)
        case .ended:
            let opts = optsRaw.map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            onEvent?(.interruptionEnded(shouldResume: opts.contains(.shouldResume)))
        @unknown default:
            break
        }
    }

    private func handleRouteChange(reasonRaw: UInt?) {
        guard let reasonRaw,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) else { return }
        if reason == .oldDeviceUnavailable { onEvent?(.routeLost) }
    }
}
