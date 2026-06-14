//  OpenAIStatusMappingTests.swift
//  Purpose: HTTP status → PipelineError mapping via an injected URLSession with a
//  stub URLProtocol (bug #8 + earlier taxonomy). No real network.

import Foundation
import Testing
@testable import vrecorder

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data(#"{"choices":[{"message":{"content":"ok"}}]}"#.utf8)
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let resp = HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                   httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

// `.serialized`: the stub's `nonisolated(unsafe)` static status/body are shared
// global state mutated per test. Only this suite touches them, so running its
// tests one-at-a-time removes the parallel-testing data race (bug #6 / GH #16).
@Suite("OpenAI HTTP status mapping", .serialized)
struct OpenAIStatusMappingTests {
    private func engine() -> OpenAITranslationEngine {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return OpenAITranslationEngine(session: URLSession(configuration: config),
                                       keyProvider: { "sk-testkey12345" })
    }

    private func expect(status: Int, to expected: PipelineError) async {
        StubURLProtocol.status = status
        await #expect(throws: expected) {
            _ = try await engine().translate("你好", from: Locale(identifier: "zh"),
                                             to: Locale(identifier: "en"))
        }
    }

    @Test func timeoutStatusesMapToTimeout() async {
        await expect(status: 408, to: .timeout)   // bug #8
        await expect(status: 504, to: .timeout)   // bug #8
    }

    @Test func authAndRateStatuses() async {
        await expect(status: 401, to: .invalidAPIKey)
        await expect(status: 429, to: .rateLimited)
    }

    @Test func successReturnsContent() async throws {
        StubURLProtocol.status = 200
        let out = try await engine().translate("你好", from: Locale(identifier: "zh"),
                                               to: Locale(identifier: "en"))
        #expect(out == "ok")
    }
}
