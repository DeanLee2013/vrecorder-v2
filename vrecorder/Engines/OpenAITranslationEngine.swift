//  OpenAITranslationEngine.swift
//  Purpose: TranslationEngine backed by OpenAI Chat Completions. Request building
//  and response parsing are pure/static so they can be unit-tested without the
//  network; `translate` does the URLSession round-trip and maps errors to
//  PipelineError. Key comes from the injected provider (Keychain-backed).

import Foundation

struct OpenAITranslationEngine: TranslationEngine {
    let capabilities = TranslationCapabilities(isOffline: false, latency: .cloud, providerName: "OpenAI")

    private let model: String
    private let keyProvider: @Sendable () -> String?
    private let session: URLSession

    init(model: String = "gpt-4o-mini",
         session: URLSession = .shared,
         keyProvider: @escaping @Sendable () -> String?) {
        self.model = model
        self.session = session
        self.keyProvider = keyProvider
    }

    func translate(_ text: String, from source: Locale, to target: Locale) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard let key = keyProvider(), !key.isEmpty else { throw PipelineError.missingAPIKey }

        let request = try Self.makeRequest(text: trimmed, target: target, model: model, apiKey: key)
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw PipelineError.providerError("no response") }
            switch http.statusCode {
            case 200: return try Self.parse(data: data)
            // A request only reaches here WITH a key, so 401/403 means the key is
            // present but wrong/revoked — not "missing" (audit-G4 #4).
            case 401, 403: throw PipelineError.invalidAPIKey
            case 429: throw PipelineError.rateLimited
            default:  throw PipelineError.providerError("HTTP \(http.statusCode)")
            }
        } catch let e as PipelineError {
            throw e
        } catch let e as URLError {
            switch e.code {
            case .timedOut:
                throw PipelineError.timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
                 .cannotFindHost, .dnsLookupFailed, .internationalRoamingOff,
                 .dataNotAllowed, .secureConnectionFailed:
                throw PipelineError.offline
            default:
                throw PipelineError.providerError("network: \(e.code.rawValue)")
            }
        }
    }

    // MARK: - Pure helpers (unit-tested)

    static func makeRequest(text: String, target: Locale, model: String, apiKey: String) throws -> URLRequest {
        let lang = target.language.languageCode?.identifier == "zh" ? "Chinese" : "English"
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "messages": [
                ["role": "system",
                 "content": "You are a simultaneous interpreter. Translate the user's text into natural, concise \(lang). Output only the translation, no quotes, no notes."],
                ["role": "user", "content": text],
            ],
        ]
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    static func parse(data: Data) throws -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw PipelineError.providerError("unparseable response") }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
