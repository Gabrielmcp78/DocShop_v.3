import Foundation
import Combine

// MARK: - Task Coordination System
class TaskCoordinator: ObservableObject {
    static let shared = TaskCoordinator()
    
    @Published var activeTasks: [AgentTask] = []
    @Published var completedTasks: [AgentTask] = []
    @Published var blockedTasks: [AgentTask] = []
    @Published var agentStates: [AgentID: AgentState] = [:]
    
    private var taskDependencies: [UUID: [UUID]] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupTaskMonitoring()
        initializeAgentStates()
    }
    
    // MARK: - Task Management
    func createTask(_ task: AgentTask) {
        activeTasks.append(task)
        updateTaskDependencies(for: task)
        notifyAgentOfNewTask(task)
        saveTaskState()
    }
    
    func updateTaskProgress(_ taskId: UUID, progress: Double) {
        if let index = activeTasks.firstIndex(where: { $0.id == taskId }) {
            activeTasks[index].progress = progress
            activeTasks[index].updatedAt = Date()
            
            // Check if task is completed
            if progress >= 1.0 {
                completeTask(taskId, result: TaskResult(taskId: taskId, success: true, data: nil, error: nil, metrics: nil, artifacts: []))
            }
            
            saveTaskState()
        }
    }
    
    func completeTask(_ taskId: UUID, result: TaskResult) {
        guard let taskIndex = activeTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var task = activeTasks[taskIndex]
        task.status = result.success ? .completed : .failed
        task.progress = result.success ? 1.0 : task.progress
        task.updatedAt = Date()
        
        // Move to completed tasks
        activeTasks.remove(at: taskIndex)
        completedTasks.append(task)
        
        // Update agent metrics
        updateAgentMetrics(for: task.assignedAgent, taskCompleted: result.success)
        
        // Check for dependent tasks
        checkDependentTasks(completedTaskId: taskId)
        
        saveTaskState()
    }
    
    func blockTask(_ taskId: UUID, reason: String) {
        guard let taskIndex = activeTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var task = activeTasks[taskIndex]
        task.status = .blocked
        task.updatedAt = Date()
        
        activeTasks.remove(at: taskIndex)
        blockedTasks.append(task)
        
        // Notify relevant agents
        notifyAgentsOfBlockedTask(task, reason: reason)
        
        saveTaskState()
    }
    
    func unblockTask(_ taskId: UUID) {
        guard let taskIndex = blockedTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var task = blockedTasks[taskIndex]
        task.status = .pending
        task.updatedAt = Date()
        
        blockedTasks.remove(at: taskIndex)
        activeTasks.append(task)
        
        // Notify agent
        notifyAgentOfNewTask(task)
        
        saveTaskState()
    }
    
    // MARK: - Dependency Management
    private func updateTaskDependencies(for task: AgentTask) {
        taskDependencies[task.id] = task.dependencies
    }
    
    private func checkDependentTasks(completedTaskId: UUID) {
        let dependentTasks = activeTasks.filter { task in
            task.dependencies.contains(completedTaskId)
        }
        
        for dependentTask in dependentTasks {
            let remainingDependencies = dependentTask.dependencies.filter { depId in
                !completedTasks.contains { $0.id == depId }
            }
            
            if remainingDependencies.isEmpty && dependentTask.status == .blocked {
                unblockTask(dependentTask.id)
            }
        }
    }
    
    // MARK: - Agent State Management
    private func initializeAgentStates() {
        for agentId in AgentID.allCases {
            agentStates[agentId] = AgentState(agentId: agentId)
        }
    }
    
    func updateAgentStatus(_ agentId: AgentID, status: AgentStatus) {
        agentStates[agentId]?.status = status
        agentStates[agentId]?.lastHeartbeat = Date()
        saveAgentState()
    }
    
    private func updateAgentMetrics(for agentId: AgentID, taskCompleted: Bool) {
        guard var state = agentStates[agentId] else { return }
        
        if taskCompleted {
            state.metrics.tasksCompleted += 1
        } else {
            state.metrics.errorCount += 1
        }
        
        agentStates[agentId] = state
        saveAgentState()
    }
    
    // MARK: - Task Monitoring
    private func setupTaskMonitoring() {
        // Monitor for stale tasks
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForStaleTasks()
            }
            .store(in: &cancellables)
        
        // Monitor agent heartbeats
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAgentHeartbeats()
            }
            .store(in: &cancellables)
    }
    
    private func checkForStaleTasks() {
        let staleThreshold: TimeInterval = 300 // 5 minutes
        let now = Date()
        
        for task in activeTasks {
            if task.status == .inProgress && now.timeIntervalSince(task.updatedAt) > staleThreshold {
                print("⚠️ Stale task detected: \(task.id) - \(task.type)")
                // Could implement automatic retry or escalation here
            }
        }
    }
    
    private func checkAgentHeartbeats() {
        let heartbeatThreshold: TimeInterval = 120 // 2 minutes
        let now = Date()
        
        for (agentId, state) in agentStates {
            if now.timeIntervalSince(state.lastHeartbeat) > heartbeatThreshold {
                print("⚠️ Agent \(agentId) heartbeat missing")
                updateAgentStatus(agentId, status: .offline)
            }
        }
    }
    
    // MARK: - Agent Notification
    private func notifyAgentOfNewTask(_ task: AgentTask) {
        // In a real implementation, this would send a message to the agent
        print("📋 Task assigned to \(task.assignedAgent): \(task.type)")
        
        // Update agent state
        agentStates[task.assignedAgent]?.currentTasks.append(task.id)
        updateAgentStatus(task.assignedAgent, status: .working)
    }
    
    private func notifyAgentsOfBlockedTask(_ task: AgentTask, reason: String) {
        print("🚫 Task blocked: \(task.id) - Reason: \(reason)")
        
        // Notify dependent agents
        let dependentAgents = activeTasks
            .filter { $0.dependencies.contains(task.id) }
            .map { $0.assignedAgent }
        
        for agentId in Set(dependentAgents) {
            print("📢 Notifying \(agentId) of blocked dependency")
        }
    }
    
    // MARK: - Persistence
    private func saveTaskState() {
        // In a real implementation, this would persist to disk or database
        let taskData = TaskStateSnapshot(
            activeTasks: activeTasks,
            completedTasks: completedTasks,
            blockedTasks: blockedTasks,
            timestamp: Date()
        )
        
        // Save to shared state
        SharedStateManager.shared.updateState(.tasks, value: taskData)
    }
    
    private func saveAgentState() {
        SharedStateManager.shared.updateState(.agentStates, value: agentStates)
    }
    
    // MARK: - Task Queries
    func getTasksForAgent(_ agentId: AgentID) -> [AgentTask] {
        return activeTasks.filter { $0.assignedAgent == agentId }
    }
    
    func getTasksForProject(_ projectId: UUID) -> [AgentTask] {
        return activeTasks.filter { $0.projectId == projectId }
    }
    
    func getTaskProgress(for projectId: UUID) -> Double {
        let projectTasks = activeTasks.filter { $0.projectId == projectId }
        guard !projectTasks.isEmpty else { return 0.0 }
        
        let totalProgress = projectTasks.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(projectTasks.count)
    }
}

// MARK: - Supporting Types
struct TaskStateSnapshot: Codable {
    let activeTasks: [AgentTask]
    let completedTasks: [AgentTask]
    let blockedTasks: [AgentTask]
    let timestamp: Date
}

// MARK: - Shared State Manager (Placeholder)
class SharedStateManager {
    static let shared = SharedStateManager()
    
    private var state: [String: Any] = [:]
    
    func updateState<T>(_ key: SharedStateKey, value: T) {
        state[key.rawValue] = value
    }
    
    func getState<T>(_ key: SharedStateKey, type: T.Type) -> T? {
        return state[key.rawValue] as? T
    }
}

extension SharedStateKey {
    static let tasks = SharedStateKey(rawValue: "coordination.tasks")!
}