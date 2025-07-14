import Foundation

// MARK: - Shared Project Model
struct SharedProject: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var requirements: String
    var documents: [UUID] // Document IDs
    let createdAt: Date
    var updatedAt: Date
    var status: ProjectStatus
    var assignedAgents: [AgentID]
    var progress: ProjectProgress
    var metadata: [String: String]
    
    init(id: UUID = UUID(), name: String, description: String, requirements: String, documents: [UUID] = [], status: ProjectStatus = .active, assignedAgents: [AgentID] = [], metadata: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.requirements = requirements
        self.documents = documents
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = status
        self.assignedAgents = assignedAgents
        self.progress = ProjectProgress()
        self.metadata = metadata
    }
}

enum ProjectStatus: String, Codable {
    case active
    case paused
    case completed
    case cancelled
    case archived
}

struct ProjectProgress: Codable {
    var overallProgress: Double = 0.0
    var documentProcessing: Double = 0.0
    var searchIndexing: Double = 0.0
    var uiImplementation: Double = 0.0
    var testing: Double = 0.0
    var lastUpdated: Date = Date()
}

// MARK: - Shared Document Model
struct SharedDocument: Codable, Identifiable {
    let id: UUID
    var title: String
    var content: String
    var url: URL?
    var filePath: String?
    let createdAt: Date
    var updatedAt: Date
    var metadata: SharedDocumentMetadata
    var processingStatus: DocumentProcessingStatus
    var searchIndexed: Bool
    var projectIds: [UUID] // Projects this document belongs to
    
    init(id: UUID = UUID(), title: String, content: String, url: URL? = nil, filePath: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.url = url
        self.filePath = filePath
        self.createdAt = Date()
        self.updatedAt = Date()
        self.metadata = SharedDocumentMetadata()
        self.processingStatus = .pending
        self.searchIndexed = false
        self.projectIds = []
    }
}

struct SharedDocumentMetadata: Codable {
    var framework: String?
    var language: String?
    var company: String?
    var topics: [String] = []
    var tags: [String] = []
    var tableOfContents: [TOCEntry] = []
    var extractedEntities: [String] = []
    var confidence: Double = 0.0
    var processingVersion: String = "1.0"
}

struct TOCEntry: Codable {
    let title: String
    let level: Int
    let anchor: String?
    let children: [TOCEntry]
}

enum DocumentProcessingStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
    case needsReprocessing
}

// MARK: - Search Models
struct SearchResult: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let title: String
    let snippet: String
    let relevanceScore: Double
    let source: SearchSource
    let metadata: [String: String]
    let highlightedText: [TextHighlight]
    
    init(documentId: UUID, title: String, snippet: String, relevanceScore: Double, source: SearchSource) {
        self.id = UUID()
        self.documentId = documentId
        self.title = title
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.source = source
        self.metadata = [:]
        self.highlightedText = []
    }
}

struct TextHighlight: Codable {
    let text: String
    let startIndex: Int
    let endIndex: Int
    let type: HighlightType
}

enum HighlightType: String, Codable {
    case exact
    case semantic
    case entity
}

enum SearchSource: String, Codable {
    case local
    case web
    case ai
    case hybrid
}

// MARK: - Agent State Models
struct AgentState: Codable {
    let agentId: AgentID
    var status: AgentStatus
    var currentTasks: [UUID]
    var completedTasks: [UUID]
    var metrics: AgentMetrics
    var lastHeartbeat: Date
    var configuration: [String: String]
    
    init(agentId: AgentID) {
        self.agentId = agentId
        self.status = .idle
        self.currentTasks = []
        self.completedTasks = []
        self.metrics = AgentMetrics()
        self.lastHeartbeat = Date()
        self.configuration = [:]
    }
}

struct AgentMetrics: Codable {
    var tasksCompleted: Int = 0
    var averageTaskTime: TimeInterval = 0.0
    var errorCount: Int = 0
    var uptime: TimeInterval = 0.0
    var memoryUsage: Int64 = 0
    var cpuUsage: Double = 0.0
}

// MARK: - Integration Models
struct IntegrationPoint: Codable {
    let id: UUID
    let name: String
    let sourceAgent: AgentID
    let targetAgent: AgentID
    let dataContract: DataContract
    var status: IntegrationStatus
    var lastTested: Date?
    var testResults: [IntegrationTestResult]
    
    init(name: String, sourceAgent: AgentID, targetAgent: AgentID, dataContract: DataContract) {
        self.id = UUID()
        self.name = name
        self.sourceAgent = sourceAgent
        self.targetAgent = targetAgent
        self.dataContract = dataContract
        self.status = .pending
        self.lastTested = nil
        self.testResults = []
    }
}

struct DataContract: Codable {
    let inputSchema: String
    let outputSchema: String
    let version: String
    let description: String
}

enum IntegrationStatus: String, Codable {
    case pending
    case testing
    case passing
    case failing
    case deprecated
}

struct IntegrationTestResult: Codable {
    let timestamp: Date
    let success: Bool
    let latency: TimeInterval
    let errorMessage: String?
    let testData: String?
}

// MARK: - Shared State Keys
enum SharedStateKey: String, CaseIterable {
    case projects = "shared.projects"
    case documents = "shared.documents"
    case agentStates = "shared.agent_states"
    case integrationPoints = "shared.integration_points"
    case systemHealth = "shared.system_health"
    case configuration = "shared.configuration"
}