import Foundation

// MARK: - Core BMad Models

struct BMadWorkflow: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: BMadWorkflowType
    let phases: [BMadWorkflowPhase]
    let context: BMadContext
    var metadata: BMadMetadata
    
    var progress: Double {
        let completedPhases = phases.filter { $0.isCompleted }.count
        return Double(completedPhases) / Double(phases.count)
    }
}

struct BMadWorkflowPhase: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let tasks: [BMadTask]
    let requiredAgents: [String]
    let dependencies: [String]
    var isCompleted: Bool = false
    
    var progress: Double {
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
}

struct BMadTask: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let type: BMadTaskType
    let assignedAgent: String
    let inputs: [String: String] // Changed from Any to String for Codable
    let outputs: [String: String] // Changed from Any to String for Codable
    var isCompleted: Bool = false
    var result: BMadTaskResult?
}

enum BMadWorkflowType: String, Codable, CaseIterable {
    case greenfieldFullstack = "greenfield-fullstack"
    case featureEnhancement = "feature-enhancement"
    case bugFix = "bug-fix"
    case codeRefactor = "code-refactor"
    case documentationUpdate = "documentation-update"
}

enum BMadTaskType: String, Codable {
    case analysis = "analysis"
    case design = "design"
    case implementation = "implementation"
    case testing = "testing"
    case review = "review"
    case documentation = "documentation"
}

struct BMadContext: Codable {
    let projectPath: String
    let targetFiles: [String]
    let requirements: [String]
    let constraints: [String]
    let metadata: [String: String]
}

struct BMadMetadata: Codable {
    let createdAt: Date
    let updatedAt: Date
    let version: String
    let author: String
    let tags: [String]
}

struct BMadTaskResult: Codable {
    let success: Bool
    let output: String
    let artifacts: [String]
    let metrics: [String: Double]
    let timestamp: Date
}

// MARK: - Agent Models

struct BMadAgent: Identifiable, Codable {
    let id = UUID()
    let name: String
    let role: String
    let capabilities: [String]
    let specializations: [String]
    let configuration: BMadAgentConfig
    var isActive: Bool = false
}

struct BMadAgentConfig: Codable {
    let maxConcurrentTasks: Int
    let timeoutSeconds: Int
    let retryAttempts: Int
    let parameters: [String: String]
}

// MARK: - Configuration Models

struct BMadCoreConfig: Codable {
    let version: String
    let methodology: BMadMethodologyConfig
    let agents: BMadAgentsConfig
    let workflows: BMadWorkflowsConfig
    let integrations: BMadIntegrationsConfig
}

struct BMadMethodologyConfig: Codable {
    let approach: String
    let principles: [String]
    let phases: [String]
    let qualityGates: [String]
}

struct BMadAgentsConfig: Codable {
    let orchestrator: BMadAgentDefinition
    let analyst: BMadAgentDefinition
    let architect: BMadAgentDefinition
    let developer: BMadAgentDefinition
    let tester: BMadAgentDefinition
    let reviewer: BMadAgentDefinition
}

struct BMadAgentDefinition: Codable {
    let role: String
    let responsibilities: [String]
    let capabilities: [String]
    let tools: [String]
    let constraints: [String]
}

struct BMadWorkflowsConfig: Codable {
    let templates: [String]
    let customWorkflows: [String]
    let defaultPhases: [String]
}

struct BMadIntegrationsConfig: Codable {
    let ide: BMadIDEIntegration
    let vcs: BMadVCSIntegration
    let ci: BMadCIIntegration
}

struct BMadIDEIntegration: Codable {
    let enabled: Bool
    let features: [String]
    let shortcuts: [String: String]
}

struct BMadVCSIntegration: Codable {
    let enabled: Bool
    let provider: String
    let branchStrategy: String
    let commitConventions: [String]
}

struct BMadCIIntegration: Codable {
    let enabled: Bool
    let provider: String
    let triggers: [String]
    let stages: [String]
}