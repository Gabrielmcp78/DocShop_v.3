import Foundation

// MARK: - Agent Communication Protocol
protocol AgentCommunication {
    var agentId: AgentID { get }
    var status: AgentStatus { get }
    
    func receiveTask(_ task: AgentTask) async throws
    func reportProgress(_ taskId: UUID, progress: Double) async
    func completeTask(_ taskId: UUID, result: TaskResult) async throws
    func requestAssistance(_ request: AssistanceRequest) async throws -> AssistanceResponse
}

// MARK: - Agent Types
enum AgentID: String, CaseIterable {
    case projectManager = "agent1-project-management"
    case documentProcessor = "agent2-document-processing"
    case searchEngine = "agent3-ai-search"
    case uiEnhancer = "agent4-ui-enhancement"
    case systemIntegrator = "agent5-system-integration"
}

enum AgentStatus: String {
    case idle
    case working
    case blocked
    case error
    case offline
}

// MARK: - Task Management
struct AgentTask: Codable, Identifiable {
    let id: UUID
    let type: TaskType
    let assignedAgent: AgentID
    let projectId: UUID?
    var status: TaskStatus
    var progress: Double
    let priority: TaskPriority
    let createdAt: Date
    var updatedAt: Date
    let dependencies: [UUID]
    let metadata: [String: String]
    
    init(id: UUID = UUID(), type: TaskType, assignedAgent: AgentID, projectId: UUID? = nil, status: TaskStatus = .pending, progress: Double = 0.0, priority: TaskPriority = .medium, dependencies: [UUID] = [], metadata: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.assignedAgent = assignedAgent
        self.projectId = projectId
        self.status = status
        self.progress = progress
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dependencies = dependencies
        self.metadata = metadata
    }
}

enum TaskType: String, Codable {
    case projectCreation
    case documentProcessing
    case metadataExtraction
    case searchIndexing
    case uiEnhancement
    case systemIntegration
    case testing
    case deployment
}

enum TaskStatus: String, Codable {
    case pending
    case inProgress
    case blocked
    case completed
    case failed
    case cancelled
}

enum TaskPriority: String, Codable {
    case low
    case medium
    case high
    case critical
}

// MARK: - Task Results
struct TaskResult: Codable {
    let taskId: UUID
    let success: Bool
    let data: Data?
    let error: String?
    let metrics: TaskMetrics?
    let artifacts: [String] // File paths or URLs to created artifacts
}

struct TaskMetrics: Codable {
    let executionTime: TimeInterval
    let memoryUsage: Int64
    let cpuUsage: Double
    let customMetrics: [String: Double]
}

// MARK: - Assistance System
struct AssistanceRequest: Codable {
    let requestingAgent: AgentID
    let targetAgent: AgentID
    let type: AssistanceType
    let context: String
    let data: Data?
}

struct AssistanceResponse: Codable {
    let success: Bool
    let data: Data?
    let message: String?
}

enum AssistanceType: String, Codable {
    case dataRequest
    case processRequest
    case validationRequest
    case integrationTest
}

// MARK: - Agent Message System
struct AgentMessage: Codable {
    let id: UUID
    let from: AgentID
    let to: AgentID
    let type: MessageType
    let payload: Data
    let timestamp: Date
    let priority: MessagePriority
    
    init(from: AgentID, to: AgentID, type: MessageType, payload: Data, priority: MessagePriority = .normal) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.type = type
        self.payload = payload
        self.timestamp = Date()
        self.priority = priority
    }
}

enum MessageType: String, Codable {
    case taskAssignment
    case progressUpdate
    case dataRequest
    case dataResponse
    case errorReport
    case statusUpdate
    case integrationTest
}

enum MessagePriority: String, Codable {
    case low
    case normal
    case high
    case urgent
}