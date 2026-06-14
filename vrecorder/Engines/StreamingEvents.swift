//  StreamingEvents.swift
//  Purpose: Shared streaming vocabulary for the pipeline. STT stages emit
//  TranscriptEvent (partial replaceable, final frozen); engines declare
//  capabilities so call sites pick by capability, not by concrete type.
//  See AGENTS.md › Engine abstraction and rules/50 › Streaming Pipeline.

import Foundation

/// One streaming result from a speech recognizer.
/// `.partial` replaces the previous partial for the active segment;
/// `.final` freezes that segment.
enum TranscriptEvent: Equatable {
    case partial(String)
    case final(String)

    var text: String {
        switch self {
        case .partial(let t), .final(let t): return t
        }
    }
}

/// Latency class lets the UI/selection logic reason about engines abstractly.
enum LatencyClass {
    case onDevice    // immediate, no network
    case cloud       // network round-trip
}

struct SpeechCapabilities {
    let supportsOnDevice: Bool
    let latency: LatencyClass
    let supportedLocales: [Locale]
}

struct TranslationCapabilities {
    let isOffline: Bool
    let latency: LatencyClass
    let providerName: String
}

/// Domain errors the UI can distinguish (never mislabel a timeout as offline).
enum PipelineError: Error, Equatable {
    case offline
    case timeout
    case rateLimited
    case permissionDenied
    case missingAPIKey
    case providerError(String)
}
