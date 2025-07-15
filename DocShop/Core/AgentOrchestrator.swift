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
    private var projectStorage = ProjectStorage.shared
   // private let benchmarkEngine = BenchmarkEngine()
    
    private init() {
        Task {
            projectQueue = await projectStorage.loadProjects()
            // If loadProjects() is not async, remove 'await' here
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
        
        // Save the new project
        projectStorage.saveProject(project)
        
        // The projectQueue is now managed by ProjectStorage, so we just update it from the source of truth
        self.projectQueue = projectStorage.projects
        
        return project
    }
    
    func assign(task: ProjectTask, to agent: DevelopmentAgent) {
        if let projectIndex = projectQueue.firstIndex(where: { $0.id == task.projectID }) {
            if let taskIndex = projectQueue[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                projectQueue[projectIndex].tasks[taskIndex].assignedAgentID = agent.id
                projectQueue[projectIndex].tasks[taskIndex].status = .assigned
                projectStorage.saveProject(projectQueue[projectIndex])
            }
        }
    }
    
    func updateStatus(for task: ProjectTask, to status: ProjectTaskStatus) {
        if let projectIndex = projectQueue.firstIndex(where: { $0.id == task.projectID }) {
            if let taskIndex = projectQueue[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                projectQueue[projectIndex].tasks[taskIndex].status = status
                projectStorage.saveProject(projectQueue[projectIndex])
            }
        }
    }
    
    func agent(for id: UUID) -> DevelopmentAgent? {
        return AgentRegistry.shared.allAgents().first(where: { $0.id == id })
    }
    
    func project(for id: UUID) -> Project? {
        return projectQueue.first(where: { $0.id == id })
    }
    
    func startProject(_ project: Project) async {
        guard let projectIndex = projectQueue.firstIndex(where: { $0.id == project.id }) else { return }
        
        await MainActor.run {
            self.projectQueue[projectIndex].status = .active
            self.systemStatus = .running
        }
        
        // Start executing tasks
        let activeTasks = project.tasks.filter { $0.status == .assigned || $0.status == .pending }
        for task in activeTasks {
            if let agentID = task.assignedAgentID,
               let agent = agent(for: agentID) {
                await executeTask(task, with: agent)
            }
        }
        
        projectStorage.saveProject(projectQueue[projectIndex])
    }
    
    func pauseProject(_ project: Project) async {
        guard let projectIndex = projectQueue.firstIndex(where: { $0.id == project.id }) else { return }
        
        await MainActor.run {
            self.projectQueue[projectIndex].status = .paused
            self.systemStatus = .paused
        }
        
        projectStorage.saveProject(projectQueue[projectIndex])
    }
    
    private func executeTask(_ task: ProjectTask, with agent: DevelopmentAgent) async {
        await agent.perform(task: task) { result in
            Task {
                await self.updateStatus(for: task, to: result.success ? .completed : .error)
            }
        }
    }
}

enum OrchestrationStatus: String, Codable {
    case idle, running, paused, error
} 
