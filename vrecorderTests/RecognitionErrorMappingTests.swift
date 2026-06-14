//  RecognitionErrorMappingTests.swift
//  Purpose: Speech-error → PipelineError classification (bug #9). Pure mapping,
//  synthetic NSErrors — no recognizer/device needed.

import Foundation
import Testing
@testable import vrecorder

@Suite("AppleSpeechRecognizer error mapping")
struct RecognitionErrorMappingTests {
    private func urlError(_ code: Int) -> NSError { NSError(domain: NSURLErrorDomain, code: code) }
    private let speechError = NSError(domain: "kAFAssistantErrorDomain", code: 203)  // no-speech

    @Test func revokedPermissionMapsToSpeechPermissionDenied() {
        // Authorization lost mid-session — any error should surface as a permission issue.
        #expect(AppleSpeechRecognizer.mapRecognitionError(speechError, authorized: false) == .speechPermissionDenied)
        #expect(AppleSpeechRecognizer.mapRecognitionError(urlError(NSURLErrorTimedOut), authorized: false) == .speechPermissionDenied)
    }

    @Test func networkFailuresMapToOfflineOrTimeout() {
        #expect(AppleSpeechRecognizer.mapRecognitionError(urlError(NSURLErrorNotConnectedToInternet), authorized: true) == .offline)
        #expect(AppleSpeechRecognizer.mapRecognitionError(urlError(NSURLErrorNetworkConnectionLost), authorized: true) == .offline)
        #expect(AppleSpeechRecognizer.mapRecognitionError(urlError(NSURLErrorTimedOut), authorized: true) == .timeout)
    }

    @Test func otherSpeechErrorsFallBackToRecognitionFailed() {
        #expect(AppleSpeechRecognizer.mapRecognitionError(speechError, authorized: true) == .recognitionFailed)
    }
}
