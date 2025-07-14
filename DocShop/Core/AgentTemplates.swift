import Foundation

/// Example: Instantiating and registering a LocalAgent
func registerExampleLocalAgent() {
    let context = AgentContext(
        agentID: UUID(),
        currentTask: nil,
        relevantDocs: [],
        requirements: ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.authentication],
            documentationRequirements: [.apiReference],
            testingRequirements: [.unit],
            performanceBenchmarks: []
        )
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
        currentTask: nil,
        relevantDocs: [],
        requirements: ProjectRequirements(
            targetLanguages: [.python],
            sdkFeatures: [.authentication],
            documentationRequirements: [.apiReference],
            testingRequirements: [.integration],
            performanceBenchmarks: []
        )
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