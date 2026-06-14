//  Log.swift
//  Purpose: Shared os.Logger handles (rule 50 §6 — no bare print() in production).

import OSLog

enum Log {
    static let subsystem = "com.vrecorder.app"
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let pipeline = Logger(subsystem: subsystem, category: "pipeline")
}
