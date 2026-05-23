import Foundation

// MARK: - Protocol

protocol LLMService: Actor {
    func generateInsight(
        from snapshot: HealthSnapshot,
        userAge: Int,
        biologicalSex: String
    ) async throws -> HealthInsight
}

// MARK: - Anthropic Provider

actor AnthropicService: LLMService {

    private let apiKey: String
    private let session: URLSession

    init() {
        self.apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        self.session = URLSession.shared
    }

    func generateInsight(
        from snapshot: HealthSnapshot,
        userAge: Int,
        biologicalSex: String
    ) async throws -> HealthInsight {
        guard !apiKey.isEmpty else { throw LLMError.missingAPIKey }

        let systemPrompt = Self.buildSystemPrompt()
        let userPrompt = Self.buildUserPrompt(snapshot: snapshot, age: userAge, sex: biologicalSex)

        let rawText = try await streamCompletion(system: systemPrompt, user: userPrompt)
        return try decodeInsight(from: rawText)
    }

    // MARK: SSE Streaming

    private func streamCompletion(system: String, user: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("text/event-stream", forHTTPHeaderField: "accept")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1024,
            "stream": true,
            "system": system,
            "messages": [["role": "user", "content": user]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.generationFailed("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw LLMError.apiError(
                statusCode: httpResponse.statusCode,
                message: "HTTP \(httpResponse.statusCode)"
            )
        }

        var accumulated = ""

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard jsonString != "[DONE]" else { break }

            guard
                let data = jsonString.data(using: .utf8),
                let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let eventType = event["type"] as? String
            else { continue }

            if eventType == "message_stop" { break }

            if eventType == "content_block_delta",
               let delta = event["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                accumulated += text
            }
        }

        return accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: JSON Decoding

    private func decodeInsight(from rawText: String) throws -> HealthInsight {
        // Strip any accidental markdown fences the model may add
        let cleaned = rawText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw LLMError.decodingFailed("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(HealthInsight.self, from: data)
        } catch {
            throw LLMError.decodingFailed(
                "JSON decode error: \(error.localizedDescription). Raw: \(cleaned.prefix(200))"
            )
        }
    }

    // MARK: Prompt Construction

    private static func buildSystemPrompt() -> String {
        """
        You are a wellness insights assistant that analyzes Apple HealthKit data and generates \
        structured health summaries. Write warmly and accessibly — no medical jargon. \
        Never diagnose conditions. Keep summaries encouraging but honest. \
        The confidenceScore should reflect data completeness: \
        0.9+ if all 5 metrics present, 0.7 if 3-4 present, 0.5 if 1-2 present.

        Respond ONLY with valid JSON matching this exact schema — no markdown, no explanation, \
        no text before or after the JSON:

        {
          "summary": "string (2-3 sentences)",
          "overall_trend": "improving" | "stable" | "declining",
          "recommendations": ["string", "string", "string"],
          "standout_metric": "string (name of most notable metric)",
          "confidence_score": number between 0.0 and 1.0
        }
        """
    }

    private static func buildUserPrompt(
        snapshot: HealthSnapshot,
        age: Int,
        sex: String
    ) -> String {
        let ageGroup = BenchmarkService.ageGroup(for: age)
        let service = BenchmarkService()
        let hrv = service.lookup(metric: "hrv_sdnn", ageGroup: ageGroup, biologicalSex: sex)
        let steps = service.lookup(metric: "steps_daily", ageGroup: ageGroup, biologicalSex: sex)
        let sleep = service.lookup(metric: "sleep_hours", ageGroup: ageGroup, biologicalSex: sex)
        let hrvStr   = hrv.map   { "\(Int($0.low))-\(Int($0.high))" } ?? "35-80"
        let stepsStr = steps.map { "\(Int($0.low))-\(Int($0.high))" } ?? "7000-10000"
        let sleepStr = sleep.map { "\(Int($0.low))-\(Int($0.high))" } ?? "7-9"

        return """
        Analyze this 7-day health summary for a \(age)-year-old \(sex):

        Steps (daily average): \(snapshot.steps / 7)
        Resting Heart Rate: \(snapshot.restingHeartRate.map { String(format: "%.0f bpm", $0) } ?? "no data")
        HRV (SDNN): \(snapshot.hrvSDNN.map { String(format: "%.1f ms", $0) } ?? "no data")
        Sleep (nightly average): \(String(format: "%.1f hours", snapshot.sleepHours / 7.0))
        Active Energy (daily average): \(String(format: "%.0f kcal", snapshot.activeEnergyKcal / 7.0))
        Date range ending: \(snapshot.date.formatted(.dateTime.month().day()))

        Reference benchmarks for this age/sex group (from published health guidelines):
        - Healthy resting HR: 60-80 bpm
        - Healthy HRV SDNN (\(age)yo): \(hrvStr) ms
        - Recommended daily steps: \(stepsStr)
        - Recommended sleep: \(sleepStr) hours
        - Active energy target: 400-600 kcal/day

        Generate a health insight JSON based on this data.
        """
    }
}

// MARK: - On-Device Provider (Stub — iOS 26 placeholder)

actor OnDeviceService: LLMService {
    func generateInsight(
        from snapshot: HealthSnapshot,
        userAge: Int,
        biologicalSex: String
    ) async throws -> HealthInsight {
        // TODO: Implement using Apple Foundation Models framework in a future session.
        // Requires: import FoundationModels, iOS 26+, Xcode 26+
        // Architecture is ready — this actor will use LanguageModelSession with
        // @Generable HealthInsight and BenchmarkLookupTool when available.
        throw LLMError.unavailable(
            "On-device inference requires iOS 26. Please select Anthropic Claude in Settings."
        )
    }
}

// MARK: - Factory

enum LLMServiceFactory {
    static func make(providerType: LLMProviderType) -> any LLMService {
        switch providerType {
        case .onDevice:  return OnDeviceService()
        case .anthropic: return AnthropicService()
        }
    }
}
