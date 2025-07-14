import Foundation
import Combine

// MARK: - Shared State Management System
class SharedStateManager: ObservableObject {
    static let shared = SharedStateManager()
    
    // Published state for real-time updates
    @Published var projects: [SharedProject] = []
    @Published var documents: [SharedDocument] = []
    @Published var agentStates: [AgentID: AgentState] = [:]
    @Published var systemHealth: SystemHealth = .unknown
    @Published var activeTasks: [AgentTask] = []
    
    // Private state storage
    private var state: [String: Any] = [:]
    private var subscribers: [String: [(Any) -> Void]] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let stateQueue = DispatchQueue(label: "shared-state", qos: .userInitiated)
    
    // Persistence
    private let persistenceManager = StatePersistenceManager()
    
    private init() {
        setupStateMonitoring()
        loadPersistedState()
        initializeAgentStates()
    }
    
    // MARK: - State Management
    func updateState<T>(_ key: SharedStateKey, value: T) {
        stateQueue.async { [weak self] in
            self?.state[key.rawValue] = value
            
            // Update published properties on main thread
            DispatchQueue.main.async {
                self?.updatePublishedState(key, value: value)
            }
            
            // Notify subscribers
            self?.notifySubscribers(key, value: value)
            
            // Persist state
            self?.persistenceManager.persistState(key, value: value)
        }
    }
    
    func getState<T>(_ key: SharedStateKey, type: T.Type) -> T? {
        return stateQueue.sync {
            return state[key.rawValue] as? T
        }
    }
    
    func subscribeToChanges(_ key: SharedStateKey, handler: @escaping (Any) -> Void) {
        stateQueue.async { [weak self] in
            if self?.subscribers[key.rawValue] == nil {
                self?.subscribers[key.rawValue] = []
            }
            self?.subscribers[key.rawValue]?.append(handler)
        }
    }
    
    // MARK: - Published State Updates
    private func updatePublishedState<T>(_ key: SharedStateKey, value: T) {
        switch key {
        case .projects:
            if let projects = value as? [SharedProject] {
                self.projects = projects
            }
        case .documents:
            if let documents = value as? [SharedDocument] {
                self.documents = documents
            }
        case .agentStates:
            if let agentStates = value as? [AgentID: AgentState] {
                self.agentStates = agentStates
            }
        case .systemHealth:
            if let health = value as? SystemHealth {
                self.systemHealth = health
            }
        case .configuration:
            // Handle configuration updates
            break
        }
    }
    
    // MARK: - Subscriber Notifications
    private func notifySubscribers<T>(_ key: SharedStateKey, value: T) {
        if let handlers = subscribers[key.rawValue] {
            for handler in handlers {
                DispatchQueue.main.async {
                    handler(value)
                }
            }
        }
    }
    
    // MARK: - Agent State Management
    private func initializeAgentStates() {
        var initialStates: [AgentID: AgentState] = [:]
        for agentId in AgentID.allCases {
            initialStates[agentId] = AgentState(agentId: agentId)
        }
        updateState(.agentStates, value: initialStates)
    }
    
    func updateAgentState(_ agentId: AgentID, update: (inout AgentState) -> Void) {
        stateQueue.async { [weak self] in
            guard var currentStates = self?.state[SharedStateKey.agentStates.rawValue] as? [AgentID: AgentState],
                  var agentState = currentStates[agentId] else { return }
            
            update(&agentState)
            agentState.lastHeartbeat = Date()
            currentStates[agentId] = agentState
            
            DispatchQueue.main.async {
                self?.updateState(.agentStates, value: currentStates)
            }
        }
    }
    
    // MARK: - Project Management
    func addProject(_ project: SharedProject) {
        var currentProjects = projects
        currentProjects.append(project)
        updateState(.projects, value: currentProjects)
    }
    
    func updateProject(_ projectId: UUID, update: (inout SharedProject) -> Void) {
        var currentProjects = projects
        if let index = currentProjects.firstIndex(where: { $0.id == projectId }) {
            update(&currentProjects[index])
            currentProjects[index].updatedAt = Date()
            updateState(.projects, value: currentProjects)
        }
    }
    
    func removeProject(_ projectId: UUID) {
        var currentProjects = projects
        currentProjects.removeAll { $0.id == projectId }
        updateState(.projects, value: currentProjects)
    }
    
    // MARK: - Document Management
    func addDocument(_ document: SharedDocument) {
        var currentDocuments = documents
        currentDocuments.append(document)
        updateState(.documents, value: currentDocuments)
    }
    
    func updateDocument(_ documentId: UUID, update: (inout SharedDocument) -> Void) {
        var currentDocuments = documents
        if let index = currentDocuments.firstIndex(where: { $0.id == documentId }) {
            update(&currentDocuments[index])
            currentDocuments[index].updatedAt = Date()
            updateState(.documents, value: currentDocuments)
        }
    }
    
    func removeDocument(_ documentId: UUID) {
        var currentDocuments = documents
        currentDocuments.removeAll { $0.id == documentId }
        updateState(.documents, value: currentDocuments)
    }
    
    // MARK: - Task Management Integration
    func updateActiveTasks(_ tasks: [AgentTask]) {
        activeTasks = tasks
        
        // Update agent states based on active tasks
        updateAgentStatesFromTasks(tasks)
    }
    
    private func updateAgentStatesFromTasks(_ tasks: [AgentTask]) {
        for agentId in AgentID.allCases {
            let agentTasks = tasks.filter { $0.assignedAgent == agentId }
            
            updateAgentState(agentId) { state in
                state.currentTasks = agentTasks.map { $0.id }
                
                // Update status based on tasks
                if agentTasks.isEmpty {
                    state.status = .idle
                } else if agentTasks.contains(where: { $0.status == .blocked }) {
                    state.status = .blocked
                } else if agentTasks.contains(where: { $0.status == .inProgress }) {
                    state.status = .working
                } else {
                    state.status = .idle
                }
            }
        }
    }
    
    // MARK: - System Health Monitoring
    private func setupStateMonitoring() {
        // Monitor agent heartbeats
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkSystemHealth()
            }
            .store(in: &cancellables)
        
        // Monitor state consistency
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.validateStateConsistency()
            }
            .store(in: &cancellables)
    }
    
    private func checkSystemHealth() {
        let now = Date()
        let healthyAgents = agentStates.values.filter { agent in
            now.timeIntervalSince(agent.lastHeartbeat) < 120 // 2 minutes
        }.count
        
        let totalAgents = AgentID.allCases.count
        let healthRatio = Double(healthyAgents) / Double(totalAgents)
        
        let newHealth: SystemHealth
        switch healthRatio {
        case 1.0:
            newHealth = .healthy
        case 0.7..<1.0:
            newHealth = .degraded
        default:
            newHealth = .unhealthy
        }
        
        if newHealth != systemHealth {
            updateState(.systemHealth, value: newHealth)
        }
    }
    
    private func validateStateConsistency() {
        // Check for orphaned documents
        let projectDocumentIds = Set(projects.flatMap { $0.documents })
        let actualDocumentIds = Set(documents.map { $0.id })
        
        let orphanedDocuments = actualDocumentIds.subtracting(projectDocumentIds)
        if !orphanedDocuments.isEmpty {
            print("⚠️ Found \(orphanedDocuments.count) orphaned documents")
        }
        
        // Check for missing documents
        let missingDocuments = projectDocumentIds.subtracting(actualDocumentIds)
        if !missingDocuments.isEmpty {
            print("⚠️ Found \(missingDocuments.count) missing documents in projects")
        }
    }
    
    // MARK: - Persistence
    private func loadPersistedState() {
        if let projects: [SharedProject] = persistenceManager.loadState(.projects) {
            self.projects = projects
            updateState(.projects, value: projects)
        }
        
        if let documents: [SharedDocument] = persistenceManager.loadState(.documents) {
            self.documents = documents
            updateState(.documents, value: documents)
        }
    }
    
    // MARK: - State Queries
    func getProjectsForAgent(_ agentId: AgentID) -> [SharedProject] {
        return projects.filter { $0.assignedAgents.contains(agentId) }
    }
    
    func getDocumentsForProject(_ projectId: UUID) -> [SharedDocument] {
        return documents.filter { $0.projectIds.contains(projectId) }
    }
    
    func getAgentWorkload(_ agentId: AgentID) -> Int {
        return agentStates[agentId]?.currentTasks.count ?? 0
    }
    
    func getSystemMetrics() -> SystemMetrics {
        let totalProjects = projects.count
        let activeProjects = projects.filter { $0.status == .active }.count
        let totalDocuments = documents.count
        let processedDocuments = documents.filter { $0.processingStatus == .completed }.count
        let healthyAgents = agentStates.values.filter { $0.status != .offline }.count
        
        return SystemMetrics(
            totalProjects: totalProjects,
            activeProjects: activeProjects,
            totalDocuments: totalDocuments,
            processedDocuments: processedDocuments,
            healthyAgents: healthyAgents,
            systemHealth: systemHealth,
            lastUpdated: Date()
        )
    }
}

// MARK: - Supporting Types
enum SystemHealth: String, Codable {
    case healthy
    case degraded
    case unhealthy
    case unknown
}

struct SystemMetrics: Codable {
    let totalProjects: Int
    let activeProjects: Int
    let totalDocuments: Int
    let processedDocuments: Int
    let healthyAgents: Int
    let systemHealth: SystemHealth
    let lastUpdated: Date
}

// MARK: - State Persistence Manager
class StatePersistenceManager {
    private let fileManager = FileManager.default
    private let stateDirectory: URL
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        stateDirectory = documentsPath.appendingPathComponent("DocShop-SharedState")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
    }
    
    func persistState<T: Codable>(_ key: SharedStateKey, value: T) {
        let url = stateDirectory.appendingPathComponent("\(key.rawValue).json")
        
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url)
        } catch {
            print("Failed to persist state for \(key.rawValue): \(error)")
        }
    }
    
    func loadState<T: Codable>(_ key: SharedStateKey) -> T? {
        let url = stateDirectory.appendingPathComponent("\(key.rawValue).json")
        
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to load state for \(key.rawValue): \(error)")
            return nil
        }
    }
    
    func clearState(_ key: SharedStateKey) {
        let url = stateDirectory.appendingPathComponent("\(key.rawValue).json")
        try? fileManager.removeItem(at: url)
    }
    
    func clearAllState() {
        try? fileManager.removeItem(at: stateDirectory)
        try? fileManager.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
    }
}