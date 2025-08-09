# Critical Implementation Roadmap - DocShop BMad Integration

## Immediate Action Items (Next 48 Hours)

### 🚨 CRITICAL PRIORITY 1: Fix Project Creation (24 hours)

**Problem**: ProjectCreationView is completely non-functional, breaking the entire user workflow.

**Files to Fix**:
1. `DocShop/Views/ProjectCreationView.swift` - Lines 67-76
2. `DocShop/Core/AgentOrchestrator.swift` - Lines 24-47

**Specific Implementation**:

```swift
// In ProjectCreationView.swift - Replace lines 67-76
Button("Create") {
    let requirements = ProjectRequirements(
        targetLanguages: Array(selectedLanguages),
        sdkFeatures: Array(selectedFeatures),
        documentationRequirements: Array(selectedDocs),
        testingRequirements: Array(selectedTests),
        performanceBenchmarks: Array(selectedBenchmarks),
        projectName: name,
        projectDescription: description
    )

    Task {
        isCreatingProject = true
        
        // Create BMad context for workflow
        let bmadContext = BMadContext(
            projectPath: FileManager.default.currentDirectoryPath,
            targetFiles: [],
            requirements: [requirements.projectDescription],
            constraints: [],
            metadata: [
                "projectType": "documentation",
                "workflowType": "greenfieldFullstack"
            ]
        )
        
        // Start BMad workflow first
        let bmadOrchestrator = BMadOrchestrator()
        await bmadOrchestrator.startWorkflow(.greenfieldFullstack, context: bmadContext)
        
        // Create project through orchestrator
        let project = await AgentOrchestrator.shared.createProject(
            from: [],
            requirements: requirements
        )
        
        // Success - dismiss view
        isPresented = false
        isCreatingProject = false
    }
}.disabled(name.isEmpty)
```

### 🚨 CRITICAL PRIORITY 2: Implement Task Execution (16 hours)

**Problem**: TaskDistributor and BMadOrchestrator have no actual execution logic.

**Files to Fix**:
1. `DocShop/Core/TaskDistributor.swift` - Complete rewrite
2. `DocShop/Core/BMadIntegration/BMadOrchestrator.swift` - Lines 78-81

**Implementation for TaskDistributor.swift**:

```swift
import Foundation
import Combine

class TaskDistributor: ObservableObject {
    @Published var activeTasks: [ProjectTask] = []
    @Published var completedTasks: [ProjectTask] = []
    
    private let bmadOrchestrator = BMadOrchestrator()
    
    func distribute(tasks: [ProjectTask], to agents: [DevelopmentAgent]) async {
        guard !agents.isEmpty else { 
            print("No agents available for task distribution")
            return 
        }
        
        await MainActor.run {
            self.activeTasks = tasks
        }
        
        for task in tasks {
            let bestAgent = selectBestAgent(for: task, from: agents)
            await assignAndExecuteTask(task, to: bestAgent)
        }
    }
    
    private func selectBestAgent(for task: ProjectTask, from agents: [DevelopmentAgent]) -> DevelopmentAgent {
        // Score agents based on task requirements
        let scoredAgents = agents.map { agent in
            (agent, calculateAgentScore(agent, for: task))
        }
        
        return scoredAgents.max(by: { $0.1 < $1.1 })?.0 ?? agents.first!
    }
    
    private func calculateAgentScore(_ agent: DevelopmentAgent, for task: ProjectTask) -> Int {
        var score = 0
        
        // Match specialization
        if task.type.rawValue.contains(agent.specialization.rawValue) {
            score += 10
        }
        
        // Match capabilities
        let taskKeywords = task.description.lowercased().components(separatedBy: " ")
        for capability in agent.capabilities {
            if taskKeywords.contains(capability.rawValue.lowercased()) {
                score += 5
            }
        }
        
        return score
    }
    
    private func assignAndExecuteTask(_ task: ProjectTask, to agent: DevelopmentAgent) async {
        // Update task assignment
        var updatedTask = task
        updatedTask.assignedAgentID = agent.id
        updatedTask.status = .assigned
        
        await MainActor.run {
            if let index = self.activeTasks.firstIndex(where: { $0.id == task.id }) {
                self.activeTasks[index] = updatedTask
            }
        }
        
        // Execute task through agent
        await agent.perform(task: updatedTask) { result in
            Task {
                await self.handleTaskCompletion(updatedTask, result: result)
            }
        }
    }
    
    private func handleTaskCompletion(_ task: ProjectTask, result: TaskResult) async {
        var completedTask = task
        completedTask.status = result.success ? .completed : .error
        
        await MainActor.run {
            // Remove from active tasks
            self.activeTasks.removeAll { $0.id == task.id }
            // Add to completed tasks
            self.completedTasks.append(completedTask)
        }
        
        print("Task '\(task.title)' completed with result: \(result.success ? "Success" : "Failure")")
        if let error = result.error {
            print("Error: \(error)")
        }
    }
}
```

### 🚨 CRITICAL PRIORITY 3: Implement Agent Execution (20 hours)

**Problem**: DevelopmentAgent.perform() has placeholder logic that doesn't actually execute tasks.

**File to Fix**: `DocShop/Core/DevelopmentAgent.swift` - Lines 28-60

**Implementation**:

```swift
func perform(task: ProjectTask, completion: @escaping (TaskResult) -> Void) async {
    await MainActor.run {
        self.currentTask = task
        self.status = .working
        self.progress = 0.0
    }
    
    do {
        let result = try await executeTaskBasedOnSpecialization(task)
        
        await MainActor.run {
            self.status = .completed
            self.progress = 1.0
        }
        
        completion(TaskResult(success: true, output: result, error: nil))
    } catch {
        await MainActor.run {
            self.status = .error
        }
        
        completion(TaskResult(success: false, output: "", error: error.localizedDescription))
    }
    
    await MainActor.run {
        self.currentTask = nil
    }
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

private func executeDocumentationTask(_ task: ProjectTask) async throws -> String {
    // Simulate documentation generation
    await updateProgress(0.3)
    
    let generator = CodeGenerator()
    let project = AgentOrchestrator.shared.project(for: task.projectID)!
    
    await updateProgress(0.7)
    
    let documentation = try await generator.generateDocumentation(for: project)
    
    await updateProgress(1.0)
    
    return documentation
}

private func executeCodeGenerationTask(_ task: ProjectTask) async throws -> String {
    await updateProgress(0.2)
    
    let project = AgentOrchestrator.shared.project(for: task.projectID)!
    
    await updateProgress(0.5)
    
    let aiEngine = AIEngine()
    let sdkOutput = try await aiEngine.generateSDK(from: project)
    
    await updateProgress(1.0)
    
    return sdkOutput
}

private func executeTestingTask(_ task: ProjectTask) async throws -> String {
    await updateProgress(0.4)
    
    let project = AgentOrchestrator.shared.project(for: task.projectID)!
    
    await updateProgress(0.8)
    
    let validator = CodeValidator()
    let validationResult = try await validator.validate(project: project)
    
    await updateProgress(1.0)
    
    return validationResult
}

private func executeAnalysisTask(_ task: ProjectTask) async throws -> String {
    await updateProgress(0.3)
    
    // Simulate document analysis
    let analyzer = AIDocumentAnalyzer()
    
    await updateProgress(0.6)
    
    let project = AgentOrchestrator.shared.project(for: task.projectID)!
    let analysisResult = try await analyzer.analyzeProject(project)
    
    await updateProgress(1.0)
    
    return analysisResult
}

private func updateProgress(_ progress: Double) async {
    await MainActor.run {
        self.progress = progress
    }
    
    // Simulate processing time
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
}
```

## Secondary Priority Items (Next 24 Hours)

### 🔥 HIGH PRIORITY 1: Connect BMad Dashboard to Real Data (16 hours)

**File**: `DocShop/Views/BMad/BMadDashboardView.swift`

**Problem**: UI shows placeholder data, no real-time updates.

**Implementation**: Add real data binding and state management.

### 🔥 HIGH PRIORITY 2: Implement Basic AI Integration (12 hours)

**File**: `DocShop/Core/GeminiAPI.swift`

**Problem**: Completely non-functional AI integration.

**Implementation**: Create working Gemini API client with proper error handling.

## Testing Checklist

After implementing the critical fixes, test these workflows:

### End-to-End Project Creation Test
1. [ ] Open DocShop application
2. [ ] Click "Create New Project"
3. [ ] Fill in project details
4. [ ] Select languages and features
5. [ ] Click "Create" button
6. [ ] Verify project appears in project list
7. [ ] Check that BMad workflow starts
8. [ ] Monitor task assignment to agents
9. [ ] Verify task execution completes

### Agent Execution Test
1. [ ] Create a project with documentation requirements
2. [ ] Verify documentation agent is assigned
3. [ ] Monitor agent progress updates
4. [ ] Check task completion status
5. [ ] Verify output is generated

### Error Handling Test
1. [ ] Test project creation with invalid data
2. [ ] Test agent execution with missing dependencies
3. [ ] Verify graceful error handling
4. [ ] Check error messages are user-friendly

## Success Criteria

✅ **Project Creation Works**: Users can successfully create projects through the UI
✅ **Tasks Execute**: Agents actually perform assigned tasks and produce output
✅ **Progress Updates**: UI shows real-time progress of task execution
✅ **Error Handling**: System gracefully handles and reports errors
✅ **BMad Integration**: BMad workflows coordinate with existing DocShop functionality

## Risk Mitigation

### If Implementation Takes Longer Than Expected:
1. **Fallback Option**: Implement mock responses for AI components
2. **Minimal Viable Product**: Focus only on project creation and basic task assignment
3. **Progressive Enhancement**: Add advanced features after core functionality works

### If AI Integration Fails:
1. Use local processing for document analysis
2. Implement rule-based task assignment
3. Add manual override capabilities

## Next Steps After Critical Fixes

1. **Week 2**: Implement remaining agent types and specializations
2. **Week 3**: Add advanced BMad workflow features
3. **Week 4**: Implement knowledge graph and search functionality
4. **Week 5**: Performance optimization and testing
5. **Week 6**: Documentation and deployment preparation

---

**IMPORTANT**: Focus exclusively on the Critical Priority items first. Do not work on secondary features until the core project creation workflow is functional.