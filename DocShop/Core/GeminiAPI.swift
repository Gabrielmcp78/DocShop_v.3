import Foundation

struct EmbedTextRequest: Codable {
    let text: String
}

struct EmbedTextResponse: Codable {
    let embedding: EmbeddingValue
}
struct EmbeddingValue: Codable {
    let value: [Float]
}

struct GeminiPromptPart: Codable {
    let text: String
}
struct GeminiPromptContent: Codable {
    let role: String
    let parts: [GeminiPromptPart]
}
struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
}
struct GeminiTextGenRequest: Codable {
    let contents: [GeminiPromptContent]
    let generationConfig: GeminiGenerationConfig
}
struct GeminiTextGenResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            let role: String
            let parts: [GeminiPromptPart]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

class GeminiAPI {
    static let embeddingURL = "https://generativelanguage.googleapis.com/v1beta/models/embedding-001:embedText"
    static let textGenURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    static func getEmbedding(for text: String) async throws -> [Float] {
        guard let apiKey = KeychainHelper.shared.loadAPIKey() else {
            throw NSError(domain: "GeminiAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not found"])
        }
        guard let url = URL(string: "\(embeddingURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = EmbedTextRequest(text: text)
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "GeminiAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Non-200 response"])
        }
        let decoded = try JSONDecoder().decode(EmbedTextResponse.self, from: data)
        return decoded.embedding.value
    }
    
    static func generateText(prompt: String, temperature: Double = 0.5, maxTokens: Int = 1024) async throws -> String {
        guard let apiKey = KeychainHelper.shared.loadAPIKey() else {
            throw NSError(domain: "GeminiAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not found"])
        }
        guard let url = URL(string: "\(textGenURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let req = GeminiTextGenRequest(
            contents: [GeminiPromptContent(role: "user", parts: [GeminiPromptPart(text: prompt)])],
            generationConfig: GeminiGenerationConfig(temperature: temperature, maxOutputTokens: maxTokens)
        )
        request.httpBody = try JSONEncoder().encode(req)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "GeminiAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Non-200 response"])
        }
        let decoded = try JSONDecoder().decode(GeminiTextGenResponse.self, from: data)
        return decoded.candidates.first?.content.parts.first?.text ?? ""
    }
} 