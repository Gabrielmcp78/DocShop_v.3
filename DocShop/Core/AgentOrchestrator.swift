import Foundation
import Combine

@MainActor
class AgentOrchestrator: ObservableObject {
    static let shared = AgentOrchestrator()
    
    @Published var activeAgents: [DevelopmentAgent] = []
    @Published var projectQueue: [Project] = []
    @Published var systemStatus: OrchestrationStatus = .idle
    
    private let taskDistributor = TaskDistributor()
    private let progressTracker = ProgressTracker()
    private let contextManager = ContextManager()
    @ObservedObject private var projectStorage = ProjectStorage.shared
   // private let benchmarkEngine = BenchmarkEngine()
    
    private init() {
        Task {
            projectQueue = try await projectStorage.loadProjects()
        }
    }
    
    func createProject(from documents: [DocumentMetaData], requirements: ProjectRequirements) async -> Project {
        var project = Project(
            name: requirements.projectName,
            description: requirements.projectDescription,
            requirements: requirements,
            documents: documents
        )
        // Register and assign agents
        let agents = AgentRegistry.shared.matchAgents(for: requirements)
        project.agents = agents.map { $0.id }
        // Generate initial tasks
        let tasks = ProjectTask.generateInitialTasks(for: project)
        project.tasks = tasks
        // Assign tasks to agents
        TaskDistributor().distribute(tasks: tasks, to: agents)
        // Add to queue
        projectQueue.append(project)
        
        try? await projectStorage.saveProject(project)
        
        return project
    }
    
    func assign(task: ProjectTask, to agent: DevelopmentAgent) {
        for (projectIndex, var project) in projectQueue.enumerated() {
            if let taskIndex = project.tasks.firstIndex(where: { $0.id == task.id }) {
                project.tasks[taskIndex].assignedAgentID = agent.id
                projectQueue[projectIndex] = project
                break
            }
        }
    }
    
    func updateStatus(for task: ProjectTask, to status: ProjectTaskStatus) {
        for (projectIndex, var project) in projectQueue.enumerated() {
            if let taskIndex = project.tasks.firstIndex(where: { $0.id == task.id }) {
                project.tasks[taskIndex].status = status
                projectQueue[projectIndex] = project
                break
            }
        }
    }
    
    func agent(for id: UUID) -> DevelopmentAgent? {
        return AgentRegistry.shared.allAgents().first(where: { $0.id == id })
    }
    
    func project(for id: UUID) -> Project? {
        return projectQueue.first(where: { $0.id == id })
    }
}

enum OrchestrationStatus: String, Codable {
    case idle, running, paused, error
} 
