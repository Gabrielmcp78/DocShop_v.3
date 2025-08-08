import Foundation
// Ensure DocumentRelationship.swift, DocumentMetaData.swift, and AnyCodable.swift are included in the same target/build.

// import DocumentRelationship
// import DocumentMetaData
// import AnyCodable

// These are not modules but types provided by sibling Swift files, so explicit module import is unnecessary unless you have set up custom modules.

// Make sure DocumentMetaData and AnyCodable are included in your build target.

// MARK: - Agent Identification

/// Agent identification enum
enum AgentID: String, Codable, CaseIterable {
    case projectManager = "agent1-project-management"
    case documentProcessor = "agent2-document-processing"
    case searchEngine = "agent3-ai-search"
    case uiEnhancer = "agent4-ui-enhancement"
    case systemIntegrator = "agent5-system-integration"
}

// MARK: - Agent Message System
/// Enhanced AgentMessage struct for reliable communication between agents
struct AgentMessage: Codable, Identifiable, Hashable {
    let id: UUID
    let from: AgentID
    let to: AgentID
    let type: MessageType
    let payload: Data
    let timestamp: Date
    let priority: MessagePriority
    let correlationId: UUID?  // For tracking related messages
    var expiresAt: Date?      // Message expiration
    var isAcknowledged: Bool  // Track if message was acknowledged
    var deliveryAttempts: Int // Track delivery attempts
    var metadata: [String: String]? // Additional metadata
    
    init(from: AgentID, to: AgentID, type: MessageType, payload: Data, priority: MessagePriority = .normal, correlationId: UUID? = nil) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.type = type
        self.payload = payload
        self.timestamp = Date()
        self.priority = priority
        self.correlationId = correlationId
        self.expiresAt = nil
        self.isAcknowledged = false
        self.deliveryAttempts = 0
        self.metadata = nil
    }
    
    /// Create a response message to this message
    func createResponse(type: MessageType, payload: Data) -> AgentMessage {
        return AgentMessage(
            from: self.to,
            to: self.from,
            type: type,
            payload: payload,
            priority: self.priority,
            correlationId: self.id
        )
    }
    
    /// Create an acknowledgment for this message
    func createAcknowledgment() -> AgentMessage {
        return createResponse(type: .acknowledgment, payload: Data())
    }
    
    /// Create a new message with updated delivery attempt count
    func withIncrementedDeliveryAttempt() -> AgentMessage {
        var updatedMessage = self
        updatedMessage.deliveryAttempts += 1
        return updatedMessage
    }
    
    /// Create a new message marked as acknowledged
    func withAcknowledged() -> AgentMessage {
        var updatedMessage = self
        updatedMessage.isAcknowledged = true
        return updatedMessage
    }
    
    /// Create a new message with expiration time
    func withExpiration(seconds: TimeInterval) -> AgentMessage {
        var updatedMessage = self
        updatedMessage.expiresAt = Date().addingTimeInterval(seconds)
        return updatedMessage
    }
    
    /// Create a new message with added metadata
    func withMetadata(_ key: String, value: String) -> AgentMessage {
        var updatedMessage = self
        var metadata = updatedMessage.metadata ?? [:]
        metadata[key] = value
        updatedMessage.metadata = metadata
        return updatedMessage
    }
    
    /// Check if the message has expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

/// Enhanced message types for agent communication
enum MessageType: String, Codable, CaseIterable {
    case taskAssignment     // Assign a task to an agent
    case progressUpdate     // Update on task progress
    case dataRequest        // Request for data
    case dataResponse       // Response with requested data
    case errorReport        // Report an error
    case statusUpdate       // Update on agent status
    case integrationTest    // Integration test message
    case acknowledgment     // Acknowledge receipt of a message
    case stateUpdate        // Update to shared state
    case stateRequest       // Request for shared state
    case coordinationRequest // Request for coordination
    case coordinationResponse // Response to coordination request
    case documentLock       // Lock a document for exclusive access
    case documentUnlock     // Release a document lock
    case heartbeat          // Agent heartbeat message
    case shutdown           // Request agent to shut down
}

/// Enhanced message priority levels
enum MessagePriority: String, Codable, CaseIterable {
    case low
    case normal
    case high
    case urgent
    case system // System-level messages that take precedence
    
    var numericValue: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .urgent: return 3
        case .system: return 4
        }
    }
}

/// Project priority levels
enum ProjectPriority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

// Enhanced ProjectContext with more comprehensive project information
struct ProjectContext: Codable, Hashable {
    static func == (lhs: ProjectContext, rhs: ProjectContext) -> Bool {
        return lhs.projectID == rhs.projectID &&
            lhs.keyInfo == rhs.keyInfo &&
            lhs.requirements == rhs.requirements &&
            lhs.priority == rhs.priority &&
            lhs.deadline == rhs.deadline &&
            lhs.stakeholders == rhs.stakeholders &&
            lhs.constraints == rhs.constraints &&
            lhs.goals == rhs.goals &&
            lhs.metrics == rhs.metrics &&
            lhs.customAttributes == rhs.customAttributes
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(projectID)
        hasher.combine(keyInfo)
        hasher.combine(requirements)
        hasher.combine(priority)
        hasher.combine(deadline)
        hasher.combine(stakeholders)
        hasher.combine(constraints)
        hasher.combine(goals)
        hasher.combine(metrics)
        hasher.combine(customAttributes)
    }

    let projectID: UUID
    let keyInfo: [String]
    let requirements: ProjectRequirements
    var priority: ProjectPriority
    var deadline: Date?
    var stakeholders: [String]?
    var constraints: [String]?
    var goals: [String]?
    var metrics: [String: Double]?
    var customAttributes: [String: String]?
    
    init(projectID: UUID, keyInfo: [String], requirements: ProjectRequirements, priority: ProjectPriority = .medium) {
        self.projectID = projectID
        self.keyInfo = keyInfo
        self.requirements = requirements
        self.priority = priority
        self.deadline = nil
        self.stakeholders = nil
        self.constraints = nil
        self.goals = nil
        self.metrics = nil
        self.customAttributes = nil
    }
}

// Enhanced AgentContext with more comprehensive context information
struct AgentContext: Codable, Hashable {
    static func == (lhs: AgentContext, rhs: AgentContext) -> Bool {
        return lhs.contextID == rhs.contextID &&
            lhs.agentID == rhs.agentID &&
            lhs.agentType == rhs.agentType &&
            lhs.capabilities == rhs.capabilities &&
            lhs.currentTask == rhs.currentTask &&
            lhs.projectContext == rhs.projectContext &&
            lhs.relevantDocs == rhs.relevantDocs &&
            lhs.documentRelationships == rhs.documentRelationships &&
            lhs.executionState == rhs.executionState &&
            lhs.memoryReferences == rhs.memoryReferences &&
            lhs.knowledgeBase == rhs.knowledgeBase &&
            lhs.previousResults == rhs.previousResults &&
            lhs.collaboratingAgents == rhs.collaboratingAgents &&
            lhs.messageQueue == rhs.messageQueue &&
            lhs.documentLocks == rhs.documentLocks &&
            lhs.sharedStateKeys == rhs.sharedStateKeys &&
            lhs.coordinationStatus == rhs.coordinationStatus &&
            lhs.systemResources == rhs.systemResources &&
            lhs.permissions == rhs.permissions &&
            lhs.constraints == rhs.constraints &&
            lhs.createdAt == rhs.createdAt &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.expiresAt == rhs.expiresAt &&
            lhs.customData == rhs.customData
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(contextID)
        hasher.combine(agentID)
        hasher.combine(agentType)
        hasher.combine(capabilities)
        hasher.combine(currentTask)
        hasher.combine(projectContext)
        hasher.combine(relevantDocs)
        hasher.combine(documentRelationships)
        hasher.combine(executionState)
        hasher.combine(memoryReferences)
        hasher.combine(knowledgeBase)
        hasher.combine(previousResults)
        hasher.combine(collaboratingAgents)
        hasher.combine(messageQueue)
        hasher.combine(documentLocks)
        hasher.combine(sharedStateKeys)
        hasher.combine(coordinationStatus)
        hasher.combine(systemResources)
        hasher.combine(permissions)
        hasher.combine(constraints)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
        hasher.combine(expiresAt)
        hasher.combine(customData)
    }

    // Core identity and task information
    let contextID: UUID
    let agentID: UUID
    let agentType: AgentSpecialization
    let capabilities: [AgentCapability]
    let currentTask: ProjectTask?
    
    // Project and document context
    let projectContext: ProjectContext?
    let relevantDocs: [DocumentMetaData]
    let documentRelationships: [DocumentRelationship]?
    
    // Execution context
    var executionState: ExecutionState
    var memoryReferences: [MemoryReference]?
    var knowledgeBase: [KnowledgeItem]?
    var previousResults: [TaskResult]?
    var collaboratingAgents: [UUID]?
    
    // Enhanced coordination and communication
    var messageQueue: [AgentMessage]?         // Queue of pending messages
    var documentLocks: [DocumentLock]?        // Documents locked by this agent
    var sharedStateKeys: [SharedStateKey]?    // Keys in shared state this agent is interested in
    var coordinationStatus: CoordinationStatus? // Current coordination status
    
    // System context
    var systemResources: SystemResources?
    var permissions: [Permission]?
    var constraints: [Constraint]?
    
    // Temporal context
    let createdAt: Date
    var updatedAt: Date
    var expiresAt: Date?
    
    // Extensibility
    var customData: [String: AnyCodable]?
    
    init(agentID: UUID, agentType: AgentSpecialization, capabilities: [AgentCapability], currentTask: ProjectTask? = nil, projectContext: ProjectContext? = nil, relevantDocs: [DocumentMetaData] = []) {
        self.contextID = UUID()
        self.agentID = agentID
        self.agentType = agentType
        self.capabilities = capabilities
        self.currentTask = currentTask
        self.projectContext = projectContext
        self.relevantDocs = relevantDocs
        self.documentRelationships = nil
        self.executionState = .initialized
        self.memoryReferences = nil
        self.knowledgeBase = nil
        self.previousResults = nil
        self.collaboratingAgents = nil
        self.messageQueue = nil
        self.documentLocks = nil
        self.sharedStateKeys = nil
        self.coordinationStatus = nil
        self.systemResources = nil
        self.permissions = nil
        self.constraints = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.expiresAt = nil
        self.customData = nil
    }
    
    // Helper method to update the context
    func updated() -> AgentContext {
        var updatedContext = self
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    // Helper method to add a memory reference
    func withMemoryReference(_ reference: MemoryReference) -> AgentContext {
        var updatedContext = self
        var references = updatedContext.memoryReferences ?? []
        references.append(reference)
        updatedContext.memoryReferences = references
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    // Helper method to add a knowledge item
    func withKnowledgeItem(_ item: KnowledgeItem) -> AgentContext {
        var updatedContext = self
        var knowledge = updatedContext.knowledgeBase ?? []
        knowledge.append(item)
        updatedContext.knowledgeBase = knowledge
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    // Helper method to add a previous result
    func withPreviousResult(_ result: TaskResult) -> AgentContext {
        var updatedContext = self
        var results = updatedContext.previousResults ?? []
        results.append(result)
        updatedContext.previousResults = results
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    // Helper method to update execution state
    func withExecutionState(_ state: ExecutionState) -> AgentContext {
        var updatedContext = self
        updatedContext.executionState = state
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    // Helper method to add custom data
    func withCustomData<T: Codable & Hashable>(_ key: String, value: T) -> AgentContext {
        var updatedContext = self
        var data = updatedContext.customData ?? [:]
        data[key] = AnyCodable(value)
        updatedContext.customData = data
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    // MARK: - Enhanced Communication Helper Methods
    
    /// Add a message to the message queue
    func withQueuedMessage(_ message: AgentMessage) -> AgentContext {
        var updatedContext = self
        var queue = updatedContext.messageQueue ?? []
        queue.append(message)
        updatedContext.messageQueue = queue
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Remove a message from the queue by ID
    func withoutQueuedMessage(id: UUID) -> AgentContext {
        var updatedContext = self
        guard var queue = updatedContext.messageQueue, !queue.isEmpty else {
            return updatedContext
        }
        queue.removeAll { $0.id == id }
        updatedContext.messageQueue = queue
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Add a document lock
    func withDocumentLock(_ lock: DocumentLock) -> AgentContext {
        var updatedContext = self
        var locks = updatedContext.documentLocks ?? []
        locks.append(lock)
        updatedContext.documentLocks = locks
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Remove a document lock by ID
    func withoutDocumentLock(id: UUID) -> AgentContext {
        var updatedContext = self
        guard var locks = updatedContext.documentLocks, !locks.isEmpty else {
            return updatedContext
        }
        locks.removeAll { $0.id == id }
        updatedContext.documentLocks = locks
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Add a shared state key
    func withSharedStateKey(_ key: SharedStateKey) -> AgentContext {
        var updatedContext = self
        var keys = updatedContext.sharedStateKeys ?? []
        keys.append(key)
        updatedContext.sharedStateKeys = keys
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Remove a shared state key by ID
    func withoutSharedStateKey(id: UUID) -> AgentContext {
        var updatedContext = self
        guard var keys = updatedContext.sharedStateKeys, !keys.isEmpty else {
            return updatedContext
        }
        keys.removeAll { $0.id == id }
        updatedContext.sharedStateKeys = keys
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Update coordination status
    func withCoordinationStatus(_ status: CoordinationStatus) -> AgentContext {
        var updatedContext = self
        updatedContext.coordinationStatus = status
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Add a collaborating agent
    func withCollaboratingAgent(_ agentID: UUID) -> AgentContext {
        var updatedContext = self
        var agents = updatedContext.collaboratingAgents ?? []
        if !agents.contains(agentID) {
            agents.append(agentID)
        }
        updatedContext.collaboratingAgents = agents
        updatedContext.updatedAt = Date()
        return updatedContext
    }
    
    /// Remove a collaborating agent
    func withoutCollaboratingAgent(_ agentID: UUID) -> AgentContext {
        var updatedContext = self
        guard var agents = updatedContext.collaboratingAgents, !agents.isEmpty else {
            return updatedContext
        }
        agents.removeAll { $0 == agentID }
        updatedContext.collaboratingAgents = agents
        updatedContext.updatedAt = Date()
        return updatedContext
    }
}

// Enhanced context alignment with more states
enum ContextAlignment: String, Codable, CaseIterable {
    case fullyAligned // Perfect alignment with requirements and goals
    case mostlyAligned // Minor deviations but generally on track
    case partiallyAligned // Some significant deviations
    case drifting // Significant deviation from requirements
    case misaligned // Completely off track
    case unknown // Alignment cannot be determined
    
    var isAcceptable: Bool {
        return self == .fullyAligned || self == .mostlyAligned
    }
}

// Execution state for tracking agent progress
enum ExecutionState: String, Codable, CaseIterable {
    case initialized // Context has been created but execution hasn't started
    case preparing // Agent is preparing for execution
    case executing // Agent is actively executing
    case waiting // Agent is waiting for external input or resources
    case paused // Execution is paused
    case completed // Execution completed successfully
    case failed // Execution failed
    case aborted // Execution was aborted
    
    var isActive: Bool {
        return self == .preparing || self == .executing || self == .waiting
    }
    
    var isTerminal: Bool {
        return self == .completed || self == .failed || self == .aborted
    }
}

// Memory reference for agent context
struct MemoryReference: Codable, Hashable, Identifiable {
    let id: UUID
    let key: String
    let type: MemoryType
    let reference: String // URI or identifier for the memory
    let timestamp: Date
    var metadata: [String: String]?
    
    enum MemoryType: String, Codable, CaseIterable {
        case shortTerm // Temporary memory for current task
        case workingMemory // Active memory for current session
        case longTerm // Persistent memory across sessions
        case episodic // Memory of specific events or experiences
        case semantic // Memory of facts and concepts
    }
    
    init(key: String, type: MemoryType, reference: String) {
        self.id = UUID()
        self.key = key
        self.type = type
        self.reference = reference
        self.timestamp = Date()
        self.metadata = nil
    }
}

// Knowledge item for agent context
struct KnowledgeItem: Codable, Hashable, Identifiable {
    let id: UUID
    let key: String
    let value: String
    let confidence: Float // 0.0 to 1.0
    let source: KnowledgeSource
    let timestamp: Date
    var metadata: [String: String]?
    
    enum KnowledgeSource: String, Codable, CaseIterable {
        case document // From a document
        case inference // Inferred by the agent
        case external // From an external source
        case user // Provided by the user
        case system // Provided by the system
    }
    
    init(key: String, value: String, confidence: Float, source: KnowledgeSource) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.source = source
        self.timestamp = Date()
        self.metadata = nil
    }
}

// System resources for agent context
struct SystemResources: Codable, Hashable {
    var cpuLimit: Double? // Percentage of CPU available
    var memoryLimit: Int64? // Bytes of memory available
    var timeLimit: TimeInterval? // Maximum execution time
    var apiRateLimit: Int? // Maximum API calls per minute
    var diskSpaceLimit: Int64? // Bytes of disk space available
    
    init() {
        self.cpuLimit = nil
        self.memoryLimit = nil
        self.timeLimit = nil
        self.apiRateLimit = nil
        self.diskSpaceLimit = nil
    }
}

// Permission for agent context
struct Permission: Codable, Hashable, Identifiable {
    let id: UUID
    let resource: String
    let action: PermissionAction
    let granted: Bool
    
    enum PermissionAction: String, Codable, CaseIterable {
        case read, write, execute, delete
    }
    
    init(resource: String, action: PermissionAction, granted: Bool) {
        self.id = UUID()
        self.resource = resource
        self.action = action
        self.granted = granted
    }
}

// Constraint for agent context
struct Constraint: Codable, Hashable, Identifiable {
    let id: UUID
    let type: ConstraintType
    let value: String
    let priority: ConstraintPriority
    
    enum ConstraintType: String, Codable, CaseIterable {
        case time // Time constraint
        case resource // Resource constraint
        case quality // Quality constraint
        case scope // Scope constraint
        case security // Security constraint
    }
    
    enum ConstraintPriority: String, Codable, CaseIterable {
        case low, medium, high, critical
    }
    
    init(type: ConstraintType, value: String, priority: ConstraintPriority = .medium) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.priority = priority
    }
}

// MARK: - Enhanced Coordination Types

/// Document lock for coordinating access to documents
struct DocumentLock: Codable, Hashable, Identifiable {
    let id: UUID
    let documentId: UUID
    let lockingAgentId: UUID
    let lockType: LockType
    let acquiredAt: Date
    var expiresAt: Date?
    var reason: String?
    
    enum LockType: String, Codable, CaseIterable {
        case read      // Multiple agents can read
        case write     // Exclusive write access
        case process   // Processing lock
    }
    
    init(documentId: UUID, lockingAgentId: UUID, lockType: LockType, expiresIn: TimeInterval? = nil) {
        self.id = UUID()
        self.documentId = documentId
        self.lockingAgentId = lockingAgentId
        self.lockType = lockType
        self.acquiredAt = Date()
        if let expiresIn = expiresIn {
            self.expiresAt = Date().addingTimeInterval(expiresIn)
        } else {
            self.expiresAt = nil
        }
        self.reason = nil
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    func withReason(_ reason: String) -> DocumentLock {
        var updatedLock = self
        updatedLock.reason = reason
        return updatedLock
    }
    
    func withExtendedExpiration(_ seconds: TimeInterval) -> DocumentLock {
        var updatedLock = self
        if let currentExpiry = updatedLock.expiresAt {
            updatedLock.expiresAt = currentExpiry.addingTimeInterval(seconds)
        } else {
            updatedLock.expiresAt = Date().addingTimeInterval(seconds)
        }
        return updatedLock
    }
}

/// Shared state key for accessing shared state
struct SharedStateKey: Codable, Hashable, Identifiable {
    let id: UUID
    let key: String
    let scope: StateScope
    let accessLevel: AccessLevel
    let ownerAgentId: UUID?
    
    enum StateScope: String, Codable, CaseIterable {
        case global    // Visible to all agents
        case project   // Scoped to a project
        case document  // Scoped to a document
        case agent     // Scoped to an agent
    }
    
    enum AccessLevel: String, Codable, CaseIterable {
        case readOnly
        case readWrite
        case owner     // Can modify access control
    }
    
    init(key: String, scope: StateScope, accessLevel: AccessLevel = .readOnly, ownerAgentId: UUID? = nil) {
        self.id = UUID()
        self.key = key
        self.scope = scope
        self.accessLevel = accessLevel
        self.ownerAgentId = ownerAgentId
    }
}

/// Coordination status for multi-agent coordination
struct CoordinationStatus: Codable, Hashable {
    var status: Status
    var coordinatingWith: [UUID]?
    var waitingFor: [UUID]?
    var blockedBy: [UUID]?
    var lastCoordinationAt: Date?
    var coordinationTimeout: TimeInterval?
    
    enum Status: String, Codable, CaseIterable {
        case idle          // Not coordinating
        case coordinating  // Actively coordinating
        case waiting       // Waiting for other agents
        case blocked       // Blocked by other agents
        case failed        // Coordination failed
    }
    
    init(status: Status = .idle) {
        self.status = status
        self.coordinatingWith = nil
        self.waitingFor = nil
        self.blockedBy = nil
        self.lastCoordinationAt = nil
        self.coordinationTimeout = nil
    }
    
    var isActive: Bool {
        return status == .coordinating || status == .waiting
    }
    
    var isBlocked: Bool {
        return status == .blocked || status == .failed
    }
    
    func withStatus(_ status: Status) -> CoordinationStatus {
        var updated = self
        updated.status = status
        updated.lastCoordinationAt = Date()
        return updated
    }
    
    func withCoordinatingAgents(_ agents: [UUID]) -> CoordinationStatus {
        var updated = self
        updated.coordinatingWith = agents
        updated.lastCoordinationAt = Date()
        return updated
    }
    
    func withWaitingFor(_ agents: [UUID]) -> CoordinationStatus {
        var updated = self
        updated.waitingFor = agents
        updated.lastCoordinationAt = Date()
        return updated
    }
    
    func withBlockedBy(_ agents: [UUID]) -> CoordinationStatus {
        var updated = self
        updated.blockedBy = agents
        updated.status = .blocked
        updated.lastCoordinationAt = Date()
        return updated
    }
    
    func withTimeout(_ seconds: TimeInterval) -> CoordinationStatus {
        var updated = self
        updated.coordinationTimeout = seconds
        return updated
    }
    
    var isTimedOut: Bool {
        guard let lastCoordinationAt = lastCoordinationAt,
              let timeout = coordinationTimeout else {
            return false
        }
        return Date().timeIntervalSince(lastCoordinationAt) > timeout
    }
}

