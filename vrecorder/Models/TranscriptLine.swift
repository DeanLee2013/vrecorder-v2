//  TranscriptLine.swift
//  Purpose: Value-type model for a single subtitle line and its lifecycle state.
//  partial is replaceable (same id, updated text); final freezes it; history
//  is a past line dimmed in place. See design/README.md › State Management.

import Foundation

enum TranscriptStatus {
    case partial   // 22pt, 62% opacity, shimmer — being replaced live
    case final     // 30pt, full brightness — frozen
    case history   // 17pt, dim — scrolled into the past
}

struct TranscriptLine: Identifiable, Equatable {
    let id: UUID
    var status: TranscriptStatus
    var text: String

    init(id: UUID = UUID(), status: TranscriptStatus, text: String) {
        self.id = id
        self.status = status
        self.text = text
    }
}
