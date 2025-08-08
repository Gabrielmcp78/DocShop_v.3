import SwiftUI

@main
struct DocShopApp: App {
    init() {
        registerExampleLocalAgent()
        registerExampleRemoteAgent()
        
        // Register additional production agents
        registerProductionAgents()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.clear // fallback for unsupported OS
                    .background(.ultraThinMaterial)
                ContentView()
            }
        }
    }
    
    #if canImport(AppIntents)
    static var appIntents: [Any] {
        [ImportDocumentationIntent()]
    }
    #endif
}

func registerProductionAgents() {
    // Swift SDK Agent
    let swiftContext = AgentContext(
        agentID: UUID(),
        agentType: .sdk,
        capabilities: [.codeGeneration, .documentation, .testing],
        currentTask: nil,
        relevantDocs: []
    )
    let swiftAgent = LocalAgent(
        id: swiftContext.agentID,
        name: "Swift SDK Specialist",
        specialization: .sdk,
        capabilities: [.codeGeneration, .documentation, .testing],
        context: swiftContext
    )
    AgentRegistry.shared.register(agent: swiftAgent)
    
    // Documentation Agent
    let docContext = AgentContext(
        agentID: UUID(),
        agentType: .documentation,
        capabilities: [.documentation, .codeGeneration],
        currentTask: nil,
        relevantDocs: []
    )
    let docAgent = LocalAgent(
        id: docContext.agentID,
        name: "Documentation Specialist",
        specialization: .documentation,
        capabilities: [.documentation, .codeGeneration],
        context: docContext
    )
    AgentRegistry.shared.register(agent: docAgent)
    
    // JavaScript Agent
    let jsContext = AgentContext(
        agentID: UUID(),
        agentType: .sdk,
        capabilities: [.codeGeneration, .testing],
        currentTask: nil,
        relevantDocs: []
    )
    let jsAgent = LocalAgent(
        id: jsContext.agentID,
        name: "JavaScript SDK Specialist",
        specialization: .sdk,
        capabilities: [.codeGeneration, .testing],
        context: jsContext
    )
    AgentRegistry.shared.register(agent: jsAgent)
    
    // Python Agent
    let pythonContext = AgentContext(
        agentID: UUID(),
        agentType: .sdk,
        capabilities: [.codeGeneration, .testing],
        currentTask: nil,
        relevantDocs: []
    )
    let pythonAgent = LocalAgent(
        id: pythonContext.agentID,
        name: "Python SDK Specialist",
        specialization: .sdk,
        capabilities: [.codeGeneration, .testing],
        context: pythonContext
    )
    AgentRegistry.shared.register(agent: pythonAgent)
}
