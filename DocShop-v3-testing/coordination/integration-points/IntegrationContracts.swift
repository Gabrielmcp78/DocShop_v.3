import Foundation

// MARK: - Integration Contracts Between Agents

// AGENT 1 ↔ AGENT 2: Project → Document Processing
struct ProjectDocumentContract {
    static let version = "1.0"
    
    // Agent 1 → Agent 2: Process documents for project
    struct ProcessDocumentsRequest: Codable {
        let projectId: UUID
        let documentIds: [UUID]
        let processingOptions: DocumentProcessingOptions
        let priority: TaskPriority
    }
    
    struct DocumentProcessingOptions: Codable {
        let extractMetadata: Bool
        let generateTOC: Bool
        let extractEntities: Bool
        let detectFramework: Bool
        let detectLanguage: Bool
    }
    
    // Agent 2 → Agent 1: Processing results
    struct ProcessDocumentsResponse: Codable {
        let projectId: UUID
        let processedDocuments: [ProcessedDocumentResult]
        let overallSuccess: Bool
        let errors: [ProcessingError]
    }
    
    struct ProcessedDocumentResult: Codable {
        let documentId: UUID
        let success: Bool
        let metadata: SharedDocumentMetadata?
        let processingTime: TimeInterval
        let error: String?
    }
}

// AGENT 2 ↔ AGENT 3: Document Processing → Search Indexing
struct DocumentSearchContract {
    static let version = "1.0"
    
    // Agent 2 → Agent 3: Index processed documents
    struct IndexDocumentsRequest: Codable {
        let documents: [DocumentIndexData]
        let indexingOptions: IndexingOptions
    }
    
    struct DocumentIndexData: Codable {
        let documentId: UUID
        let title: String
        let content: String
        let metadata: SharedDocumentMetadata
        let projectIds: [UUID]
    }
    
    struct IndexingOptions: Codable {
        let enableSemanticSearch: Bool
        let enableFullTextSearch: Bool
        let generateEmbeddings: Bool
        let extractKeywords: Bool
    }
    
    // Agent 3 → Agent 2: Indexing results
    struct IndexDocumentsResponse: Codable {
        let indexedDocuments: [IndexedDocumentResult]
        let searchCapabilities: [SearchCapability]
        let overallSuccess: Bool
    }
    
    struct IndexedDocumentResult: Codable {
        let documentId: UUID
        let indexed: Bool
        let searchableFields: [String]
        let embeddingGenerated: Bool
        let error: String?
    }
    
    enum SearchCapability: String, Codable {
        case fullText
        case semantic
        case metadata
        case hybrid
    }
}

// AGENT 3 ↔ AGENT 4: Search Results → UI Display
struct SearchUIContract {
    static let version = "1.0"
    
    // Agent 3 → Agent 4: Search results for display
    struct SearchResultsData: Codable {
        let query: String
        let results: [SearchResult]
        let totalResults: Int
        let searchTime: TimeInterval
        let suggestions: [String]
        let filters: [SearchFilter]
    }
    
    struct SearchFilter: Codable {
        let name: String
        let type: FilterType
        let options: [FilterOption]
        let applied: Bool
    }
    
    struct FilterOption: Codable {
        let value: String
        let label: String
        let count: Int
    }
    
    enum FilterType: String, Codable {
        case framework
        case language
        case company
        case topic
        case dateRange
        case fileType
    }
    
    // Agent 4 → Agent 3: Search requests from UI
    struct SearchRequest: Codable {
        let query: String
        let filters: [AppliedFilter]
        let sortBy: SortOption
        let limit: Int
        let offset: Int
        let projectId: UUID?
    }
    
    struct AppliedFilter: Codable {
        let field: String
        let values: [String]
        let operator: FilterOperator
    }
    
    enum FilterOperator: String, Codable {
        case equals
        case contains
        case startsWith
        case range
    }
    
    enum SortOption: String, Codable {
        case relevance
        case date
        case title
        case framework
    }
}

// AGENT 1 ↔ AGENT 4: Project Management → UI Updates
struct ProjectUIContract {
    static let version = "1.0"
    
    // Agent 1 → Agent 4: Project state updates
    struct ProjectStateUpdate: Codable {
        let projectId: UUID
        let state: ProjectUIState
        let timestamp: Date
    }
    
    struct ProjectUIState: Codable {
        let project: SharedProject
        let progress: ProjectProgress
        let activeTasks: [TaskSummary]
        let recentActivity: [ActivityItem]
        let agentStatus: [AgentID: AgentStatus]
    }
    
    struct TaskSummary: Codable {
        let id: UUID
        let type: TaskType
        let assignedAgent: AgentID
        let progress: Double
        let status: TaskStatus
        let estimatedCompletion: Date?
    }
    
    struct ActivityItem: Codable {
        let timestamp: Date
        let type: ActivityType
        let description: String
        let agentId: AgentID?
        let relatedTaskId: UUID?
    }
    
    enum ActivityType: String, Codable {
        case projectCreated
        case documentAdded
        case taskCompleted
        case agentAssigned
        case errorOccurred
        case milestoneReached
    }
    
    // Agent 4 → Agent 1: UI actions
    struct ProjectUIAction: Codable {
        let projectId: UUID
        let action: UIActionType
        let parameters: [String: String]
        let userId: String?
    }
    
    enum UIActionType: String, Codable {
        case createProject
        case updateProject
        case deleteProject
        case addDocument
        case removeDocument
        case assignAgent
        case pauseProject
        case resumeProject
    }
}

// AGENT 5 ↔ ALL AGENTS: System Integration Contracts
struct SystemIntegrationContract {
    static let version = "1.0"
    
    // Agent 5 → All Agents: Health check requests
    struct HealthCheckRequest: Codable {
        let requestId: UUID
        let timestamp: Date
        let checkType: HealthCheckType
    }
    
    enum HealthCheckType: String, Codable {
        case basic
        case detailed
        case performance
        case integration
    }
    
    // All Agents → Agent 5: Health check responses
    struct HealthCheckResponse: Codable {
        let requestId: UUID
        let agentId: AgentID
        let status: AgentHealthStatus
        let metrics: AgentMetrics
        let capabilities: [String]
        let issues: [HealthIssue]
        let timestamp: Date
    }
    
    enum AgentHealthStatus: String, Codable {
        case healthy
        case degraded
        case unhealthy
        case offline
    }
    
    struct HealthIssue: Codable {
        let severity: IssueSeverity
        let description: String
        let component: String
        let suggestedAction: String?
    }
    
    enum IssueSeverity: String, Codable {
        case low
        case medium
        case high
        case critical
    }
    
    // Agent 5 → All Agents: Integration test requests
    struct IntegrationTestRequest: Codable {
        let testId: UUID
        let testType: IntegrationTestType
        let sourceAgent: AgentID
        let targetAgent: AgentID
        let testData: Data?
        let expectedResult: String?
    }
    
    enum IntegrationTestType: String, Codable {
        case dataFlow
        case communication
        case performance
        case errorHandling
        case endToEnd
    }
    
    // All Agents → Agent 5: Integration test results
    struct IntegrationTestResponse: Codable {
        let testId: UUID
        let success: Bool
        let latency: TimeInterval
        let resultData: Data?
        let errorMessage: String?
        let metrics: TestMetrics?
    }
    
    struct TestMetrics: Codable {
        let memoryUsage: Int64
        let cpuUsage: Double
        let networkCalls: Int
        let customMetrics: [String: Double]
    }
}

// MARK: - Contract Validation
protocol ContractValidator {
    static func validateRequest<T: Codable>(_ request: T, contract: String) -> ValidationResult
    static func validateResponse<T: Codable>(_ response: T, contract: String) -> ValidationResult
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
}

struct ValidationError {
    let field: String
    let message: String
    let code: String
}

struct ValidationWarning {
    let field: String
    let message: String
    let suggestion: String?
}

// MARK: - Contract Registry
class ContractRegistry {
    static let shared = ContractRegistry()
    
    private var contracts: [String: ContractDefinition] = [:]
    
    private init() {
        registerContracts()
    }
    
    private func registerContracts() {
        // Register all integration contracts
        contracts["project-document"] = ContractDefinition(
            name: "Project Document Processing",
            version: ProjectDocumentContract.version,
            sourceAgent: .projectManager,
            targetAgent: .documentProcessor
        )
        
        contracts["document-search"] = ContractDefinition(
            name: "Document Search Indexing",
            version: DocumentSearchContract.version,
            sourceAgent: .documentProcessor,
            targetAgent: .searchEngine
        )
        
        contracts["search-ui"] = ContractDefinition(
            name: "Search UI Integration",
            version: SearchUIContract.version,
            sourceAgent: .searchEngine,
            targetAgent: .uiEnhancer
        )
        
        contracts["project-ui"] = ContractDefinition(
            name: "Project UI Integration",
            version: ProjectUIContract.version,
            sourceAgent: .projectManager,
            targetAgent: .uiEnhancer
        )
        
        contracts["system-integration"] = ContractDefinition(
            name: "System Integration",
            version: SystemIntegrationContract.version,
            sourceAgent: .systemIntegrator,
            targetAgent: .systemIntegrator // All agents
        )
    }
    
    func getContract(_ name: String) -> ContractDefinition? {
        return contracts[name]
    }
    
    func getAllContracts() -> [ContractDefinition] {
        return Array(contracts.values)
    }
}

struct ContractDefinition {
    let name: String
    let version: String
    let sourceAgent: AgentID
    let targetAgent: AgentID
    let description: String?
    let lastUpdated: Date
    
    init(name: String, version: String, sourceAgent: AgentID, targetAgent: AgentID, description: String? = nil) {
        self.name = name
        self.version = version
        self.sourceAgent = sourceAgent
        self.targetAgent = targetAgent
        self.description = description
        self.lastUpdated = Date()
    }
}