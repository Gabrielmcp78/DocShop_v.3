import Foundation

protocol AgentExecutor {
    func execute(task: ProjectTask, for agent: DevelopmentAgent, completion: @escaping (TaskResult) -> Void)
}

class LocalAgentExecutor: AgentExecutor {
    func execute(task: ProjectTask, for agent: DevelopmentAgent, completion: @escaping (TaskResult) -> Void) {
        // Execute the task locally using the agent's perform method
        agent.perform(task: task, completion: completion)
    }
}

class RemoteAgentExecutor: AgentExecutor {
    func execute(task: ProjectTask, for agent: DevelopmentAgent, completion: @escaping (TaskResult) -> Void) {
        // Simulate a remote REST/gRPC call (replace with real remote logic as needed)
        Task {
            do {
                // Simulate network delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                // Simulate remote execution by calling agent.perform (in real use, this would be a network call)
                agent.perform(task: task) { result in
                    // In real remote, handle network errors, serialization, etc.
                    completion(TaskResult(success: result.success, output: "[Remote] " + (result.output ?? ""), error: result.error ?? ""))
                }
            } catch {
                completion(TaskResult(success: false, output: "", error: "Remote execution failed: \(error.localizedDescription)"))
            }
        }
    }
} 
