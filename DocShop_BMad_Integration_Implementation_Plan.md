# DocShop BMad Integration Implementation Plan

## Executive Summary

The DocShop application currently has a non-functional BMad integration system with placeholder UI components and incomplete backend logic. This plan outlines the complete implementation needed to create a working multi-agent system orchestrated through BMad methodology.

## Current State Analysis

### Working Components ✅
- Core document management (DocumentProcessor, DocumentStorage, LibraryView)
- Basic UI framework (ContentView, DocumentDetailView, etc.)
- Data models (Project, DocumentMetaData, BMadModels)
- Configuration loading (BMadConfigManager - partial)

### Non-Functional Components ❌
- **Critical**: Project creation workflow completely broken
- **Critical**: Agent orchestration system non-functional
- **Critical**: BMad workflow execution missing
- **Critical**: Task distribution system incomplete
- **High**: AI integration (GeminiAPI, AIDocumentAnalyzer)
- **High**: Agent execution logic missing

## Implementation Phases

### Phase 1: Core System Foundation (Critical - 48 hours)

#### 1.1 Fix Project Creation System
**Files to modify:**
- `DocShop/Views/ProjectCreationView.swift`
- `DocShop/Core/AgentOrchestrator.swift`
- `DocShop/Data/ProjectStorage.swift`

**Implementation:**
```swift
// Fix ProjectCreationView.swift - Connect to BMad workflow
private func createProject() {
    let requirements = ProjectRequirements(...)
    
    Task {
        isCreatingProject = true
        
        // Create BMad context
        let bmadContext = BMadContext(
            projectPath: FileManager.default.currentDirectoryPath,
            targetFiles: [],
            requirements: [requirements.projectDescription],
            constraints: [],
            metadata: ["projectType": "documentation"]
        )
        
        // Start BMad workflow
        await bmadOrchestrator.startWorkflow(.greenfieldFullstack, context: bmadContext)
        
        // Create project through orchestrator
        let project = await AgentOrchestrator.shared.createProject(
            from: selectedDocuments,
            requirements: requirements
        )
        
        isPresented = false
        isCreatingProject = false
    }
}
```

#### 1.2 Implement Task Distribution System
**File:** `DocShop/Core/TaskDistributor.swift`

**Current Issues:**
- Calls `agent.perform(task:)` but agents are non-functional
- No connection to BMad workflow system
- Missing error handling

**Implementation:**
```swift
class TaskDistributor {
    private let bmadOrchestrator = BMadOrchestrator()
    
    func distribute(tasks: [ProjectTask], to agents: [DevelopmentAgent]) async {
        // Convert ProjectTasks to BMadTasks
        let bmadTasks = tasks.map { projectTask in
            BMadTask(
                name: projectTask.title,
                description: projectTask.description,
                type: mapTaskType(projectTask.type),
                assignedAgent: selectBestAgent(for: projectTask, from: agents).name,
                inputs: projectTask.context.toDictionary(),
                outputs: [:]
            )
        }
        
        // Execute through BMad workflow
        for task in bmadTasks {
            try await bmadOrchestrator.executeTask(task, with: agents)
        }
    }
}
```

#### 1.3 Complete BMad Orchestrator Implementation
**File:** `DocShop/Core/BMadIntegration/BMadOrchestrator.swift`

**Missing Implementation:**
```swift
private func executeTask(_ task: BMadTask, with agents: [BMadAgent]) async throws {
    // Find appropriate agent
    guard let agent = agents.first(where: { $0.name == task.assignedAgent }) else {
        throw BMadError.agentNotFound(task.assignedAgent)
    }
    
    // Execute based on task type
    switch task.type {
    case .analysis:
        try await executeAnalysisTask(task, with: agent)
    case .implementation:
        try await executeImplementationTask(task, with: agent)
    case .documentation:
        try await executeDocumentationTask(task, with: agent)
    default:
        try await executeGenericTask(task, with: agent)
    }
}

private func executeAnalysisTask(_ task: BMadTask, with agent: BMadAgent) async throws {
    // Implement document analysis logic
    let analyzer = AIDocumentAnalyzer()
    let result = try await analyzer.analyzeDocuments(task.inputs)
    
    // Update task result
    await updateTaskResult(task, result: result)
}
```

### Phase 2: Agent System Implementation (High - 32 hours)

#### 2.1 Implement DevelopmentAgent Execution Logic
**File:** `DocShop/Core/DevelopmentAgent.swift`

**Current Issues:**
- `perform(task:)` method has placeholder logic
- No actual AI integration
- Missing specialized agent behaviors

**Implementation:**
```swift
func perform(task: ProjectTask, completion: @escaping (TaskResult) -> Void) async {
    self.currentTask = task
    self.status = .working
    self.progress = 0.0
    
    do {
        let result = try await executeTaskBasedOnSpecialization(task)
        
        self.status = .completed
        self.progress = 1.0
        completion(TaskResult(success: true, output: result, error: nil))
    } catch {
        self.status = .error
        completion(TaskResult(success: false, output: "", error: error.localizedDescription))
    }
    
    self.currentTask = nil
}

private func executeTaskBasedOnSpecialization(_ task: ProjectTask) async throws -> String {
    switch specialization {
    case .documentation:
        return try await executeDocumentationTask(task)
    case .codeGeneration:
        return try await executeCodeGenerationTask(task)
    case .testing:
        return try await executeTestingTask(task)
    case .analysis:
        return try await executeAnalysisTask(task)
    }
}
```

#### 2.2 Implement AI Integration
**Files:**
- `DocShop/Core/GeminiAPI.swift`
- `DocShop/Core/AIDocumentAnalyzer.swift`
- `DocShop/Core/SmartDocumentProcessor.swift`

**GeminiAPI Implementation:**
```swift
class GeminiAPI: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    init() {
        self.apiKey = KeychainHelper.shared.getAPIKey(for: "gemini") ?? ""
    }
    
    func generateContent(prompt: String, context: [String] = []) async throws -> String {
        let request = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: prompt)])],
            generationConfig: GeminiGenerationConfig()
        )
        
        // Implement actual API call
        let response = try await performAPICall(request)
        return response.candidates.first?.content.parts.first?.text ?? ""
    }
    
    func analyzeDocument(_ document: DocumentMetaData) async throws -> DocumentAnalysis {
        let prompt = createAnalysisPrompt(for: document)
        let result = try await generateContent(prompt: prompt)
        return parseAnalysisResult(result)
    }
}
```

### Phase 3: UI Integration (High - 24 hours)

#### 3.1 Connect BMad Dashboard to Backend
**File:** `DocShop/Views/BMad/BMadDashboardView.swift`

**Current Issues:**
- UI components exist but don't connect to actual data
- No real-time updates from orchestrator
- Missing error handling

**Implementation:**
```swift
struct BMadDashboardView: View {
    @StateObject private var orchestrator = BMadOrchestrator()
    @StateObject private var integration = DocShopBMadIntegration()
    @State private var selectedWorkflowType: BMadWorkflowType = .greenfieldFullstack
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Real-time workflow status
                if let currentWorkflow = orchestrator.currentWorkflow {
                    WorkflowProgressView(
                        workflow: currentWorkflow,
                        state: orchestrator.workflowState
                    )
                }
                
                // Active agents with real data
                ActiveAgentsGridView(agents: orchestrator.activeAgents)
                
                // Task queue with progress
                TaskQueueView(tasks: getCurrentTasks())
            }
        }
        .onAppear {
            orchestrator.loadConfiguration()
            integration.analyzeCurrentState()
        }
    }
}
```

#### 3.2 Fix Project Creation UI Integration
**File:** `DocShop/Views/ProjectCreationView.swift`

**Implementation:**
```swift
// Add BMad workflow selection
Section(header: Text("BMad Workflow")) {
    Picker("Workflow Type", selection: $selectedWorkflowType) {
        ForEach(BMadWorkflowType.allCases, id: \.self) { type in
            Text(type.displayName).tag(type)
        }
    }
    .pickerStyle(SegmentedPickerStyle())
}

// Enhanced create button logic
Button("Create with BMad") {
    Task {
        isCreatingProject = true
        
        // Create BMad context
        let context = BMadContext(
            projectPath: FileManager.default.currentDirectoryPath,
            targetFiles: selectedDocuments.map { $0.filePath },
            requirements: [description],
            constraints: [],
            metadata: ["type": selectedWorkflowType.rawValue]
        )
        
        // Start BMad workflow
        await bmadOrchestrator.startWorkflow(selectedWorkflowType, context: context)
        
        isPresented = false
        isCreatingProject = false
    }
}
```

### Phase 4: Advanced Features (Medium - 28 hours)

#### 4.1 Implement Context Management
**File:** `DocShop/Core/ContextManager.swift`

#### 4.2 Add Document Search and Indexing
**File:** `DocShop/Core/DocumentSearchIndex.swift`

#### 4.3 Implement Knowledge Graph Integration
**File:** `DocShop/Core/Neo4jManager.swift`

## Implementation Priority Matrix

| Component | Priority | Effort | Dependencies | BMad Integration |
|-----------|----------|--------|--------------|------------------|
| ProjectCreationView | Critical | 24h | AgentOrchestrator, BMadOrchestrator | Required |
| AgentOrchestrator | Critical | 32h | TaskDistributor, DevelopmentAgent | Required |
| TaskDistributor | Critical | 16h | BMadOrchestrator | Required |
| BMadOrchestrator.executeTask | Critical | 24h | BMadWorkflowEngine | Core |
| DevelopmentAgent.perform | High | 20h | GeminiAPI, AIDocumentAnalyzer | Required |
| GeminiAPI | High | 12h | KeychainHelper | Required |
| BMadDashboardView | High | 16h | BMadOrchestrator | Required |
| AIDocumentAnalyzer | High | 16h | GeminiAPI | Required |
| ContextManager | Medium | 12h | None | Optional |
| DocumentSearchIndex | Medium | 12h | None | Optional |

## System Architecture Integration

### Data Flow
1. **Project Creation** → BMadOrchestrator → WorkflowEngine → TaskDistributor → Agents
2. **Document Processing** → AIDocumentAnalyzer → ContextManager → Agent Context
3. **Task Execution** → DevelopmentAgent → GeminiAPI → TaskResult → UI Updates

### Component Relationships
```
BMadOrchestrator (Central Hub)
├── BMadWorkflowEngine (Workflow Management)
├── BMadAgentManager (Agent Lifecycle)
├── TaskDistributor (Task Assignment)
└── DocShopBMadIntegration (UI Bridge)

AgentOrchestrator (Legacy Bridge)
├── DevelopmentAgent (Agent Implementation)
├── ContextManager (Context Tracking)
└── ProjectStorage (Data Persistence)
```

## Testing Strategy

### Unit Tests
- BMadOrchestrator workflow execution
- TaskDistributor agent assignment
- DevelopmentAgent task performance
- GeminiAPI integration

### Integration Tests
- End-to-end project creation
- BMad workflow execution
- UI component data binding
- Error handling scenarios

### Manual Testing Checklist
- [ ] Create new project through UI
- [ ] Verify BMad workflow starts
- [ ] Check agent assignment
- [ ] Monitor task execution
- [ ] Validate UI updates
- [ ] Test error scenarios

## Risk Mitigation

### High-Risk Areas
1. **AI API Integration** - Implement fallback mechanisms
2. **Async Task Coordination** - Add comprehensive error handling
3. **UI State Management** - Use proper @Published properties
4. **Data Persistence** - Implement backup/recovery

### Fallback Strategies
- Mock AI responses for development
- Graceful degradation when APIs fail
- Local task execution when remote fails
- Manual task assignment override

## Success Metrics

### Functional Requirements
- [ ] Project creation completes successfully
- [ ] BMad workflows execute end-to-end
- [ ] Agents perform assigned tasks
- [ ] UI reflects real-time progress
- [ ] Error handling works correctly

### Performance Requirements
- Project creation < 30 seconds
- Task assignment < 5 seconds
- UI updates < 1 second latency
- Memory usage < 500MB

## Next Steps

1. **Immediate (Week 1)**: Implement Phase 1 - Core System Foundation
2. **Short-term (Week 2-3)**: Implement Phase 2 - Agent System
3. **Medium-term (Week 4)**: Implement Phase 3 - UI Integration
4. **Long-term (Week 5-6)**: Implement Phase 4 - Advanced Features

## Conclusion

This implementation plan addresses all critical gaps in the DocShop BMad integration system. The phased approach ensures that core functionality is established first, followed by enhanced features. The estimated total effort is 132 hours across 4 phases, with the most critical components prioritized for immediate implementation.