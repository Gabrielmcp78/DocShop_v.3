# BMad-DocShop Integration Implementation Plan

## Overview

DocShop needs to become the **programmatic execution engine** for the BMad methodology. This means building systems that can:

1. **Parse and execute BMad agent definitions**
2. **Orchestrate workflows programmatically**
3. **Provide oversight and validation**
4. **Manage document and file operations**
5. **Track progress and state**

## Phase 1: Core Agent System Integration

### 1.1 BMad Agent Parser
**Location**: `DocShop/Core/BmadAgentParser.swift`

```swift
struct BmadAgent {
    let id: String
    let name: String
    let title: String
    let persona: AgentPersona
    let commands: [String: AgentCommand]
    let dependencies: AgentDependencies
    let whenToUse: String
}

struct AgentPersona {
    let role: String
    let style: String
    let identity: String
    let focus: String
    let corePrinciples: [String]
}

class BmadAgentParser {
    func parseAgent(from markdownFile: String) -> BmadAgent
    func loadAgentDependencies(_ agent: BmadAgent) -> [BmadResource]
    func validateAgentDefinition(_ agent: BmadAgent) -> ValidationResult
}
```

### 1.2 Agent Execution Engine
**Location**: `DocShop/Core/AgentExecutionEngine.swift`

```swift
class AgentExecutionEngine {
    func executeAgent(_ agent: BmadAgent, with context: ExecutionContext) async -> AgentResult
    func executeCommand(_ command: String, agent: BmadAgent, context: ExecutionContext) async -> CommandResult
    func loadAgentResources(_ dependencies: AgentDependencies) async -> [BmadResource]
}

struct ExecutionContext {
    let projectPath: String
    let currentWorkflow: BmadWorkflow?
    let availableDocuments: [DocumentMetaData]
    let userInput: String?
    let previousResults: [AgentResult]
}
```

### 1.3 Workflow Orchestrator
**Location**: `DocShop/Core/BmadWorkflowOrchestrator.swift`

```swift
class BmadWorkflowOrchestrator {
    func loadWorkflow(_ workflowId: String) -> BmadWorkflow
    func executeWorkflowStep(_ step: WorkflowStep, context: ExecutionContext) async -> StepResult
    func validateStepCompletion(_ step: WorkflowStep, result: StepResult) -> Bool
    func getNextStep(_ workflow: BmadWorkflow, currentStep: Int) -> WorkflowStep?
}

struct BmadWorkflow {
    let id: String
    let name: String
    let description: String
    let sequence: [WorkflowStep]
    let decisionGuidance: DecisionGuidance
}

struct WorkflowStep {
    let agent: String
    let creates: String?
    let requires: [String]
    let optionalSteps: [String]?
    let notes: String
    let condition: String?
}
```

## Phase 2: Document and Task Management

### 2.1 BMad Document Manager
**Location**: `DocShop/Core/BmadDocumentManager.swift`

```swift
class BmadDocumentManager {
    func createDocumentFromTemplate(_ templateId: String, context: TemplateContext) async -> DocumentMetaData
    func shardDocument(_ document: DocumentMetaData, destination: String) async -> [DocumentMetaData]
    func validateDocumentStructure(_ document: DocumentMetaData, against: DocumentTemplate) -> ValidationResult
    func trackDocumentChanges(_ document: DocumentMetaData, changes: [DocumentChange])
}

struct TemplateContext {
    let variables: [String: Any]
    let userInputs: [String: String]
    let projectContext: ProjectContext
}
```

### 2.2 Task Execution System
**Location**: `DocShop/Core/BmadTaskExecutor.swift`

```swift
class BmadTaskExecutor {
    func executeTask(_ taskId: String, context: TaskContext) async -> TaskResult
    func loadTaskDefinition(_ taskId: String) -> BmadTask
    func validateTaskPrerequisites(_ task: BmadTask, context: TaskContext) -> Bool
    func trackTaskProgress(_ task: BmadTask, progress: TaskProgress)
}

struct BmadTask {
    let id: String
    let name: String
    let instructions: [TaskInstruction]
    let prerequisites: [String]
    let outputs: [String]
    let elicitationRequired: Bool
}
```

## Phase 3: AI Integration Layer

### 3.1 AI Agent Interface
**Location**: `DocShop/Core/AIAgentInterface.swift`

```swift
protocol AIAgentInterface {
    func executeAgentPrompt(_ prompt: String, persona: AgentPersona) async -> AIResponse
    func processUserElicitation(_ questions: [ElicitationQuestion]) async -> [String: String]
    func validateOutput(_ output: String, against: ValidationCriteria) async -> ValidationResult
}

class GeminiAgentInterface: AIAgentInterface {
    // Implementation using Gemini API
}

class LocalAgentInterface: AIAgentInterface {
    // Implementation using local AI models
}
```

### 3.2 Oversight and Validation System
**Location**: `DocShop/Core/BmadOversightSystem.swift`

```swift
class BmadOversightSystem {
    func validateWorkflowStep(_ step: WorkflowStep, result: StepResult) async -> OversightResult
    func checkQualityGates(_ artifact: DocumentMetaData, criteria: QualityCriteria) async -> QualityResult
    func requireUserApproval(_ decision: OversightDecision) async -> Bool
    func trackWorkflowProgress(_ workflow: BmadWorkflow, currentStep: Int)
}

struct OversightDecision {
    let type: DecisionType
    let context: String
    let options: [String]
    let recommendation: String?
}
```

## Phase 4: UI Integration

### 4.1 Workflow Management UI
**Location**: `DocShop/Views/BmadWorkflowView.swift`

```swift
struct BmadWorkflowView: View {
    @StateObject private var orchestrator = BmadWorkflowOrchestrator()
    @State private var currentWorkflow: BmadWorkflow?
    @State private var currentStep: Int = 0
    @State private var stepResults: [StepResult] = []
    
    var body: some View {
        VStack {
            WorkflowProgressView(workflow: currentWorkflow, currentStep: currentStep)
            CurrentStepView(step: currentWorkflow?.sequence[currentStep])
            StepResultsView(results: stepResults)
            WorkflowControlsView(orchestrator: orchestrator)
        }
    }
}
```

### 4.2 Agent Dashboard
**Location**: `DocShop/Views/BmadAgentDashboard.swift`

```swift
struct BmadAgentDashboard: View {
    @StateObject private var agentManager = BmadAgentManager()
    @State private var activeAgent: BmadAgent?
    @State private var agentResults: [AgentResult] = []
    
    var body: some View {
        HStack {
            AgentListView(agents: agentManager.availableAgents)
            if let agent = activeAgent {
                AgentExecutionView(agent: agent, results: $agentResults)
            }
        }
    }
}
```

## Phase 5: Integration with Existing DocShop

### 5.1 Project Model Enhancement
**Update**: `DocShop/Models/Project.swift`

```swift
extension Project {
    var bmadWorkflow: BmadWorkflow? { get set }
    var currentWorkflowStep: Int { get set }
    var workflowState: WorkflowState { get set }
    var agentResults: [AgentResult] { get set }
    
    mutating func startBmadWorkflow(_ workflowId: String) {
        // Initialize BMad workflow
    }
    
    mutating func advanceWorkflowStep(_ result: StepResult) {
        // Progress to next step
    }
}
```

### 5.2 Document Integration
**Update**: `DocShop/Models/DocumentMetaData.swift`

```swift
extension DocumentMetaData {
    var bmadTemplate: String? { get set }
    var bmadContext: TemplateContext? { get set }
    var workflowArtifact: Bool { get set }
    var shardedFrom: UUID? { get set }
    var shardDestination: String? { get set }
}
```

## Implementation Priority

### Week 1-2: Foundation
1. **BmadAgentParser** - Parse agent definitions from .bmad-core
2. **Basic AgentExecutionEngine** - Execute simple agent commands
3. **Document integration** - Connect BMad templates to DocShop documents

### Week 3-4: Workflow System
1. **BmadWorkflowOrchestrator** - Load and execute workflows
2. **Task execution** - Implement task runner
3. **Basic UI** - Workflow progress view

### Week 5-6: AI Integration
1. **AI Agent Interface** - Connect to Gemini/local AI
2. **Oversight system** - Quality gates and validation
3. **User interaction** - Elicitation and approval flows

### Week 7-8: Polish and Testing
1. **Full UI integration** - Complete dashboard
2. **Error handling** - Robust error recovery
3. **Testing** - Comprehensive test suite

## Key Integration Points

### 1. Configuration Bridge
- Load `.bmad-core/core-config.yaml` in DocShop startup
- Map BMad paths to DocShop document storage
- Sync BMad preferences with DocShop settings

### 2. Document Flow
- BMad templates → DocShop DocumentMetaData
- BMad sharding → DocShop document relationships
- BMad validation → DocShop quality checks

### 3. Agent Execution
- BMad agent definitions → DocShop AI integration
- BMad tasks → DocShop automated operations
- BMad oversight → DocShop user approval flows

### 4. Workflow State
- BMad workflow progress → DocShop project state
- BMad artifacts → DocShop document library
- BMad decisions → DocShop audit trail

## Success Metrics

1. **Can load and parse all BMad agents** from `.bmad-core/agents/`
2. **Can execute a complete workflow** (e.g., greenfield-fullstack)
3. **Documents created match BMad templates** exactly
4. **User can approve/reject at decision points** 
5. **Workflow state persists** across DocShop sessions
6. **Integration feels seamless** - BMad methodology, DocShop execution

This integration will make DocShop the **first programmatic implementation** of the BMad methodology - a revolutionary step forward in AI-assisted development!