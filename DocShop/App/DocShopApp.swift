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
}

func registerProductionAgents() {
    // Swift SDK Agent
    let swiftContext = AgentContext(
        agentID: UUID(),
        currentTask: nil,
        relevantDocs: [],
        requirements: ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.authentication, .errorHandling, .logging, .asyncSupport],
            documentationRequirements: [.apiReference, .gettingStarted],
            testingRequirements: [.unit, .integration],
            performanceBenchmarks: [.latency, .correctness]
        )
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
        currentTask: nil,
        relevantDocs: [],
        requirements: ProjectRequirements(
            targetLanguages: [.swift, .javascript, .python],
            sdkFeatures: [.codeExamples],
            documentationRequirements: [.apiReference, .tutorials, .gettingStarted],
            testingRequirements: [],
            performanceBenchmarks: [.docCompleteness]
        )
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
        currentTask: nil,
        relevantDocs: [],
        requirements: ProjectRequirements(
            targetLanguages: [.javascript],
            sdkFeatures: [.authentication, .errorHandling, .asyncSupport],
            documentationRequirements: [.apiReference],
            testingRequirements: [.unit, .e2e],
            performanceBenchmarks: [.latency, .correctness]
        )
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
        currentTask: nil,
        relevantDocs: [],
        requirements: ProjectRequirements(
            targetLanguages: [.python],
            sdkFeatures: [.authentication, .errorHandling, .asyncSupport],
            documentationRequirements: [.apiReference],
            testingRequirements: [.unit, .integration],
            performanceBenchmarks: [.latency, .correctness]
        )
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
