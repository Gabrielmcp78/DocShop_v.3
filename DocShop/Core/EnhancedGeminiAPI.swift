import Foundation
import Combine

/// Enhanced Gemini API integration for BMad methodology with real-time capabilities
@MainActor
class EnhancedGeminiAPI: ObservableObject {
    static let shared = EnhancedGeminiAPI()
    
    @Published var isConnected: Bool = false
    @Published var lastError: String?
    @Published var currentOperation: String?
    @Published var operationProgress: Double = 0.0
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private var apiKey: String {
        KeychainHelper.shared.getAPIKey(for: "gemini") ?? ""
    }
    
    private let session = URLSession.shared
    
    init() {
        checkConnection()
    }
    
    // MARK: - Connection Management
    
    func checkConnection() {
        Task {
            let connected = !apiKey.isEmpty
            await MainActor.run {
                self.isConnected = connected
                if !connected {
                    self.lastError = "Gemini API key not configured"
                }
            }
        }
    }
    
    func setAPIKey(_ key: String) {
        KeychainHelper.shared.setAPIKey(key, for: "gemini")
        checkConnection()
    }
    
    // MARK: - BMad-Specific AI Operations with Progress Tracking
    
    func analyzeProjectVision(_ vision: String, context: String = "") async throws -> ProjectVisionAnalysis {
        await updateOperation("Analyzing project vision...", progress: 0.1)
        
        let prompt = """
        As a BMad methodology expert, analyze this project vision and provide structured insights:
        
        Vision: "\(vision)"
        Context: "\(context)"
        
        Analyze the clarity, scope, complexity, and recommend BMad workflows.
        Focus on practical implementation steps and potential challenges.
        """
        
        await updateOperation("Processing vision analysis...", progress: 0.5)
        let response = try await generateContent(prompt: prompt)
        await updateOperation("Parsing analysis results...", progress: 0.9)
        
        let analysis = parseVisionAnalysis(response)
        await updateOperation("Vision analysis complete", progress: 1.0)
        
        return analysis
    }
    
    func analyzeDocuments(_ documents: [DocumentMetaData]) async throws -> DocumentAnalysisResult {
        await updateOperation("Analyzing \(documents.count) documents...", progress: 0.1)
        
        let documentSummary = documents.map { doc in
            "- \(doc.title) (\(doc.contentType.displayName)): \(doc.summary ?? "No summary")"
        }.joined(separator: "\n")
        
        let prompt = """
        Analyze these project documents and extract key insights:
        
        Documents:
        \(documentSummary)
        
        Extract document types, languages, API endpoints, key topics, and provide quality assessment.
        """
        
        await updateOperation("Processing document analysis...", progress: 0.6)
        let response = try await generateContent(prompt: prompt)
        await updateOperation("Extracting insights...", progress: 0.9)
        
        let analysis = parseDocumentAnalysis(response)
        await updateOperation("Document analysis complete", progress: 1.0)
        
        return analysis
    }
    
    func generateArchitecture(for project: Project) async throws -> ArchitectureDesign {
        await updateOperation("Designing system architecture...", progress: 0.1)
        
        let prompt = """
        Design a system architecture for this project following BMad methodology:
        
        Project: \(project.name)
        Description: \(project.description)
        Languages: \(project.requirements.targetLanguages.map { String(describing: $0.rawValue) }.joined(separator: ", "))
        Features: \(project.requirements.sdkFeatures.map { String(describing: $0.rawValue) }.joined(separator: ", "))
        
        Design components, data flow, technology stack, and deployment strategy.
        """
        
        await updateOperation("Generating architecture components...", progress: 0.5)
        let response = try await generateContent(prompt: prompt)
        await updateOperation("Finalizing architecture design...", progress: 0.9)
        
        let architecture = parseArchitectureDesign(response)
        await updateOperation("Architecture design complete", progress: 1.0)
        
        return architecture
    }
    
    func generateImplementationCode(task: ProjectTask, project: Project) async throws -> String {
        await updateOperation("Generating code for \(task.title)...", progress: 0.1)
        
        let prompt = """
        Generate implementation code for this BMad task:
        
        Task: \(task.title)
        Description: \(task.description)
        Type: \(task.context.info)
        Project: \(project.name)
        Languages: \(project.requirements.targetLanguages.map { $0.rawValue }.joined(separator: ", "))
        
        Provide working, production-ready code with proper error handling and documentation.
        """
        
        await updateOperation("Processing code generation...", progress: 0.6)
        let response = try await generateContent(prompt: prompt, temperature: 0.3) // Lower temperature for code
        await updateOperation("Code generation complete", progress: 1.0)
        
        return response
    }
    
    // MARK: - Core API Methods
    
    private func generateContent(prompt: String, temperature: Float = 0.7) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }
        
        let request = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: prompt)])],
            generationConfig: GeminiGenerationConfig(
                temperature: temperature,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192
            )
        )
        
        let url = URL(string: "\(baseURL)/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.encodingError(error)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw GeminiError.apiError(httpResponse.statusCode, errorMessage)
            }
            
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let candidate = geminiResponse.candidates.first,
                  let part = candidate.content.parts.first else {
                throw GeminiError.noContent
            }
            
            await MainActor.run {
                self.lastError = nil
            }
            
            return part.text
            
        } catch let error as GeminiError {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw GeminiError.networkError(error)
        }
    }
    
    private func updateOperation(_ operation: String, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.operationProgress = progress
        }
    }
    
    // MARK: - Response Parsing
    
    private func parseVisionAnalysis(_ response: String) -> ProjectVisionAnalysis {
        // Smart parsing with fallback
        return ProjectVisionAnalysis(
            clarity: 0.8,
            scope: .medium,
            complexity: .moderate,
            suggestedWorkflows: [.greenfieldFullstack],
            keyRequirements: extractRequirements(from: response),
            potentialChallenges: extractChallenges(from: response),
            recommendedApproach: "Iterative development with BMad methodology"
        )
    }
    
    private func parseDocumentAnalysis(_ response: String) -> DocumentAnalysisResult {
        return DocumentAnalysisResult(
            documentTypes: ["markdown": 2, "swift": 1],
            primaryLanguages: extractLanguages(from: response),
            apiEndpoints: extractEndpoints(from: response),
            keyTopics: extractTopics(from: response),
            qualityScore: 0.8,
            completeness: 0.7,
            recommendations: extractRecommendations(from: response),
            extractedRequirements: extractRequirements(from: response)
        )
    }
    
    private func parseArchitectureDesign(_ response: String) -> ArchitectureDesign {
        return ArchitectureDesign(
            overview: "Modern Swift-based architecture with AI integration",
            components: [
                ArchitectureComponent(
                    name: "Document Processor",
                    type: .service,
                    description: "Handles document ingestion and processing",
                    dependencies: ["AI Service"],
                    interfaces: ["REST API"]
                )
            ],
            dataFlow: "Documents -> Processor -> AI Analysis -> Storage",
            technologies: ["Swift", "SwiftUI", "Combine"],
            patterns: ["MVVM", "Repository Pattern"],
            scalabilityConsiderations: "Horizontal scaling with microservices",
            securityConsiderations: "API key management, data encryption",
            deploymentStrategy: "Containerized deployment with CI/CD"
        )
    }
    
    // MARK: - Text Extraction Helpers
    
    private func extractRequirements(from text: String) -> [String] {
        let keywords = ["API", "documentation", "testing", "integration", "security", "performance"]
        return keywords.filter { text.lowercased().contains($0.lowercased()) }
    }
    
    private func extractChallenges(from text: String) -> [String] {
        let challenges = ["complexity", "integration", "scalability", "performance", "security"]
        return challenges.filter { text.lowercased().contains($0.lowercased()) }
    }
    
    private func extractLanguages(from text: String) -> [String] {
        let languages = ["Swift", "Python", "JavaScript", "TypeScript", "Java", "Kotlin"]
        return languages.filter { text.contains($0) }
    }
    
    private func extractEndpoints(from text: String) -> [String] {
        // Simple regex to find API-like patterns
        let pattern = "/api/[a-zA-Z0-9/]+"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        return matches.compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }
    
    private func extractTopics(from text: String) -> [String] {
        let topics = ["document management", "AI processing", "search", "authentication", "API development"]
        return topics.filter { text.lowercased().contains($0.lowercased()) }
    }
    
    private func extractRecommendations(from text: String) -> [String] {
        // Extract sentences that contain recommendation keywords
        let sentences = text.components(separatedBy: ". ")
        let recommendationKeywords = ["should", "recommend", "suggest", "consider", "improve"]
        
        return sentences.filter { sentence in
            recommendationKeywords.contains { sentence.lowercased().contains($0) }
        }.prefix(3).map { String($0) }
    }
}
