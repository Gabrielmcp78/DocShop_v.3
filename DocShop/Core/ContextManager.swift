import Foundation
import Combine

class ContextManager: ObservableObject {
    private var projectContexts: [UUID: ProjectContext] = [:]
    private var agentContexts: [UUID: AgentContext] = [:]
    
    func createProjectContext(_ project: Project) async -> ProjectContext {
        // Extract key info from docs, requirements
        let keyInfo = project.documents.map { $0.summary }
        let context = ProjectContext(
            projectID: project.id,
            keyInfo: keyInfo as! [String],
            requirements: project.requirements
        )
        DispatchQueue.main.async {
            self.projectContexts[project.id] = context
        }
        return context
    }
    
    func injectContext(to agent: DevelopmentAgent, context: AgentContext) async {
        // Send focused context to agent, update understanding
        agent.context = context
        DispatchQueue.main.async {
            self.agentContexts[agent.id] = context
        }
    }
    
    func monitorContextAlignment(_ agent: DevelopmentAgent) async throws -> ContextAlignment {
        // Simulate context alignment check (e.g., compare agent state to context)
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        let aligned = Bool.random()
        return aligned ? .aligned : .drifting
    }
} 
