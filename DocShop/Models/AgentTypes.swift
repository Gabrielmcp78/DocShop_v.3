import Foundation

enum AgentSpecialization: String, Codable, CaseIterable {
    case backend, frontend, ai, sdk, documentation, testing, devops
}

enum AgentCapability: String, Codable, CaseIterable {
    case codeGeneration, analysis, testing, documentation, integration, monitoring
}

enum AgentStatus: String, Codable {
    case idle, assigned, working, blocked, completed, error
}

struct TaskResult: Codable {
    let success: Bool
    let output: String
    let error: String?
} 