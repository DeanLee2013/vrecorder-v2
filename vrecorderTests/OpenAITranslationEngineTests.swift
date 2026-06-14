//  OpenAITranslationEngineTests.swift
//  Purpose: Pure request-building and response-parsing coverage (no network).

import Foundation
import Testing
@testable import vrecorder

@Suite("OpenAITranslationEngine")
struct OpenAITranslationEngineTests {
    @Test func requestHasAuthHeaderAndJSONBody() throws {
        let req = try OpenAITranslationEngine.makeRequest(
            text: "你好", target: Locale(identifier: "en"), model: "gpt-4o-mini", apiKey: "sk-test")
        #expect(req.httpMethod == "POST")
        #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(req.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        let body = try #require(req.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "gpt-4o-mini")
    }

    @Test func targetEnglishVsChineseChangesSystemPrompt() throws {
        func systemPrompt(_ target: String) throws -> String {
            let req = try OpenAITranslationEngine.makeRequest(
                text: "x", target: Locale(identifier: target), model: "m", apiKey: "k")
            let json = try JSONSerialization.jsonObject(with: req.httpBody!) as! [String: Any]
            let messages = json["messages"] as! [[String: Any]]
            return messages.first!["content"] as! String
        }
        #expect(try systemPrompt("en").contains("English"))
        #expect(try systemPrompt("zh").contains("Chinese"))
    }

    @Test func parsesContentFromChoices() throws {
        let payload = """
        {"choices":[{"message":{"role":"assistant","content":"  Hello there.  "}}]}
        """.data(using: .utf8)!
        #expect(try OpenAITranslationEngine.parse(data: payload) == "Hello there.")
    }

    @Test func parseThrowsOnGarbage() {
        let bad = Data("not json".utf8)
        #expect(throws: PipelineError.self) { try OpenAITranslationEngine.parse(data: bad) }
    }

    @Test func emptyInputReturnsEmptyWithoutCallingNetwork() async throws {
        let engine = OpenAITranslationEngine(keyProvider: { "sk-test" })
        let out = try await engine.translate("   ", from: Locale(identifier: "zh"), to: Locale(identifier: "en"))
        #expect(out.isEmpty)
    }

    @Test func missingKeyThrows() async {
        let engine = OpenAITranslationEngine(keyProvider: { nil })
        await #expect(throws: PipelineError.missingAPIKey) {
            _ = try await engine.translate("你好", from: Locale(identifier: "zh"), to: Locale(identifier: "en"))
        }
    }
}
