import Foundation

/// Example: Instantiating and registering a LocalAgent
func registerExampleLocalAgent() {
    let context = AgentContext(
        agentID: UUID(),
        agentType: .sdk,
        capabilities: [.codeGeneration, .documentation],
        currentTask: nil,
        projectContext: nil,
        relevantDocs: []
    )
    let agent = LocalAgent(
        id: context.agentID,
        name: "Swift Specialist",
        specialization: .sdk,
        capabilities: [.codeGeneration, .documentation],
        context: context
    )
    AgentRegistry.shared.register(agent: agent)
}

/// Example: Instantiating and registering a RemoteAgent
func registerExampleRemoteAgent() {
    let context = AgentContext(
        agentID: UUID(),
        agentType: .sdk,
        capabilities: [.codeGeneration, .testing],
        currentTask: nil,
        projectContext: nil,
        relevantDocs: []
    )
    let endpoint = URL(string: "https://agent-cloud.example.com/execute")!
    let agent = RemoteAgent(
        id: context.agentID,
        name: "Python Cloud Agent",
        specialization: .sdk,
        capabilities: [.codeGeneration, .testing],
        context: context,
        endpoint: endpoint,
        platform: "cloud"
    )
    AgentRegistry.shared.register(agent: agent)
}

// Call these functions at app startup or in tests to populate the registry with example agents. 
