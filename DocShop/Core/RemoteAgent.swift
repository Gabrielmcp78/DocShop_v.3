import Foundation
// Import AgentSpecialization, AgentCapability, AgentContext, TaskResult from Models

class RemoteAgent: DevelopmentAgent {
    let endpoint: URL
    let platform: String
    let executor: AgentExecutor = RemoteAgentExecutor()
    
    init(id: UUID = UUID(), name: String, specialization: AgentSpecialization, capabilities: [AgentCapability], context: AgentContext, endpoint: URL, platform: String) {
        self.endpoint = endpoint
        self.platform = platform
        super.init(id: id, name: name, specialization: specialization, capabilities: capabilities, context: context)
    }
    
    override func perform(task: ProjectTask, completion: @escaping (TaskResult) -> Void) {
        executor.execute(task: task, for: self, completion: completion)
    }
} 