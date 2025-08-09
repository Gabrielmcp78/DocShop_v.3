import Foundation

// MARK: - Gemini API Request/Response Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Float
    let topK: Int
    let topP: Float
    let maxOutputTokens: Int
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

// MARK: - BMad-Specific Analysis Models

struct ProjectVisionAnalysis: Codable {
    let clarity: Float // 0.0 to 1.0
    let scope: ProjectScope
    let complexity: ProjectComplexity
    let suggestedWorkflows: [BMadWorkflowType]
    let keyRequirements: [String]
    let potentialChallenges: [String]
    let recommendedApproach: String
}

enum ProjectScope: String, Codable {
    case small = "small"
    case medium = "medium" 
    case large = "large"
    case enterprise = "enterprise"
}

enum ProjectComplexity: String, Codable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case expert = "expert"
}

struct DocumentAnalysisResult: Codable {
    let documentTypes: [String: Int] // type -> count
    let primaryLanguages: [String]
    let apiEndpoints: [String]
    let keyTopics: [String]
    let qualityScore: Float // 0.0 to 1.0
    let completeness: Float // 0.0 to 1.0
    let recommendations: [String]
    let extractedRequirements: [String]
}

struct WorkflowRecommendation: Codable {
    let recommendedWorkflow: BMadWorkflowType
    let confidence: Float // 0.0 to 1.0
    let reasoning: String
    let alternativeWorkflows: [BMadWorkflowType]
    let estimatedDuration: String
    let requiredSkills: [String]
    let riskFactors: [String]
}

struct ArchitectureDesign: Codable {
    let overview: String
    let components: [ArchitectureComponent]
    let dataFlow: String
    let technologies: [String]
    let patterns: [String]
    let scalabilityConsiderations: String
    let securityConsiderations: String
    let deploymentStrategy: String
}

struct ArchitectureComponent: Codable {
    let name: String
    let type: ComponentType
    let description: String
    let dependencies: [String]
    let interfaces: [String]
}

enum ComponentType: String, Codable {
    case frontend = "frontend"
    case backend = "backend"
    case database = "database"
    case api = "api"
    case service = "service"
    case library = "library"
}

struct ImplementationPlan: Codable {
    let phases: [ImplementationPhase]
    let totalEstimate: String
    let criticalPath: [String]
    let dependencies: [String]
    let riskMitigation: [String]
    let qualityGates: [String]
}

struct ImplementationPhase: Codable {
    let name: String
    let description: String
    let tasks: [ImplementationTask]
    let duration: String
    let dependencies: [String]
    let deliverables: [String]
}

struct ImplementationTask: Codable {
    let name: String
    let description: String
    let effort: String
    let skills: [String]
    let priority: TaskPriority
    let type: BMadTaskType
}

struct GeneratedDocumentation: Codable {
    let title: String
    let content: String
    let sections: [DocumentSection]
    let metadata: DocumentMetadata
}

struct DocumentSection: Codable {
    let title: String
    let content: String
    let level: Int
    let type: SectionType
}

enum SectionType: String, Codable {
    case overview = "overview"
    case installation = "installation"
    case usage = "usage"
    case api = "api"
    case examples = "examples"
    case troubleshooting = "troubleshooting"
}

struct DocumentMetadata: Codable {
    let wordCount: Int
    let estimatedReadingTime: String
    let lastUpdated: Date
    let version: String
}

// MARK: - Error Types

enum GeminiError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case noContent
    case encodingError(Error)
    case networkError(Error)
    case apiError(Int, String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Gemini API key not configured"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .noContent:
            return "No content received from Gemini API"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}