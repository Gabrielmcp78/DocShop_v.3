import Foundation
// Import TaskResult from Models

class LocalAgent: DevelopmentAgent {
    let platform: String = "local"
    let executor: AgentExecutor = LocalAgentExecutor()
    
    override func perform(task: ProjectTask, completion: @escaping (TaskResult) -> Void) {
        executor.execute(task: task, for: self, completion: completion)
    }
} 