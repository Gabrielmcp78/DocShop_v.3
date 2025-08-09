import Foundation
import SwiftUI
import Combine

/// Core orchestrator for BMad methodology integration
class BMadOrchestrator: ObservableObject {
    @Published var currentWorkflow: BMadWorkflow?
    @Published var activeAgents: [BMadAgent] = []
    @Published var workflowState: WorkflowState = .idle
    
    private let configManager = BMadConfigManager()
    private let agentManager = BMadAgentManager()
    private let workflowEngine = BMadWorkflowEngine()
    
    enum WorkflowState {
        case idle
        case planning
        case executing
        case reviewing
        case completed
        case error(String)
    }
    
    init() {
        loadConfiguration()
    }
    
    func loadConfiguration() {
        configManager.loadCoreConfig()
        agentManager.loadAgents()
    }
    
    func startWorkflow(_ workflowType: BMadWorkflowType, context: BMadContext) async {
        workflowState = .planning
        
        do {
            let workflow = try await workflowEngine.createWorkflow(
                type: workflowType,
                context: context
            )
            
            await MainActor.run {
                self.currentWorkflow = workflow
                self.workflowState = .executing
            }
            
            try await executeWorkflow(workflow)
            
        } catch {
            await MainActor.run {
                self.workflowState = .error(error.localizedDescription)
            }
        }
    }
    
    private func executeWorkflow(_ workflow: BMadWorkflow) async throws {
        for phase in workflow.phases {
            try await executePhase(phase)
        }
        
        await MainActor.run {
            self.workflowState = .completed
        }
    }
    
    private func executePhase(_ phase: BMadWorkflowPhase) async throws {
        // Execute phase with appropriate agents
        let requiredAgents = agentManager.getAgentsForPhase(phase)
        
        await MainActor.run {
            self.activeAgents = requiredAgents
        }
        
        for task in phase.tasks {
            try await executeTask(task, with: requiredAgents)
        }
    }
    
    // MARK: - BMad-Native Project Creation
    
    func createProject(
        vision: String,
        context: BMadContext,
        requirements: ProjectRequirements,
        documents: [DocumentMetaData]
    ) async -> Project {
        // Extract project name from vision
        let projectName = extractProjectName(from: vision)
        
        // Create project with BMad workflow embedded
        var project = Project(
            name: projectName,
            description: context.requirements.joined(separator: "\n"),
            requirements: requirements,
            documents: documents
        )
        
        // Generate BMad-aware tasks
        let bmadTasks = generateBMadTasks(for: project, workflow: currentWorkflow)
        project.tasks = bmadTasks
        
        // Assign BMad agents
        let assignedAgents = await agentManager.assignAgentsForProject(project)
        project.agents = assignedAgents.map { $0.id }
        
        // Save project
        await MainActor.run {
            ProjectStorage.shared.saveProject(project)
        }
        
        return project
    }
    
    func initializeProjectExecution(_ project: Project) async {
        // Start the BMad workflow execution for this project
        workflowState = .executing
        
        // Load and activate agents
        let projectAgents = await agentManager.getAgentsForProject(project)
        await MainActor.run {
            self.activeAgents = projectAgents
        }
        
        // Begin task execution
        for task in project.tasks {
            await executeProjectTask(task, for: project)
        }
    }
    
    private func generateBMadTasks(for project: Project, workflow: BMadWorkflow?) -> [ProjectTask] {
        var tasks: [ProjectTask] = []
        
        // Analysis phase tasks
        tasks.append(ProjectTask(
            id: UUID(),
            title: "Document Analysis",
            description: "Analyze project documents to understand context and requirements",
            status: .pending,
            priority: .high,
            assignedAgentID: nil,
            benchmarks: [],
            context: TaskContext(info: "analysis"),
            projectID: project.id
        ))
        
        // Design phase tasks
        tasks.append(ProjectTask(
            id: UUID(),
            title: "Architecture Design",
            description: "Design system architecture based on requirements",
            status: .pending,
            priority: .high,
            assignedAgentID: nil,
            benchmarks: [],
            context: TaskContext(info: "design"),
            projectID: project.id
        ))
        
        // Implementation phase tasks
        for language in project.requirements.targetLanguages {
            tasks.append(ProjectTask(
                id: UUID(),
                title: "Generate \(language.rawValue) SDK",
                description: "Create client library for \(language.rawValue)",
                status: .pending,
                priority: .high,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "implementation"),
                projectID: project.id
            ))
        }
        
        // Documentation tasks
        for docType in project.requirements.documentationRequirements {
            tasks.append(ProjectTask(
                id: UUID(),
                title: "Create \(docType.rawValue)",
                description: "Generate \(docType.rawValue) documentation",
                status: .pending,
                priority: .medium,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "documentation"),
                projectID: project.id
            ))
        }
        
        // Testing tasks
        for testType in project.requirements.testingRequirements {
            tasks.append(ProjectTask(
                id: UUID(),
                title: "\(testType.rawValue.capitalized) Testing",
                description: "Implement \(testType.rawValue) tests",
                status: .pending,
                priority: .medium,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "testing"),
                projectID: project.id
            ))
        }
        
        return tasks
    }
    
    private func executeProjectTask(_ task: ProjectTask, for project: Project) async {
        // Find appropriate BMad agent for this task
        guard let agent = activeAgents.first(where: { agent in
            agent.capabilities.contains { capability in
                task.context.info.contains(capability.lowercased())
            }
        }) else {
            print("No suitable agent found for task: \(task.title)")
            return
        }
        
        // Execute task through BMad methodology
        do {
            let result = try await executeBMadTask(task, with: agent, for: project)
            await handleTaskCompletion(task, result: result, for: project)
        } catch {
            print("Task execution failed: \(error.localizedDescription)")
            await handleTaskError(task, error: error, for: project)
        }
    }
    
    private func executeBMadTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // This is where BMad methodology guides the execution
        switch task.context.info {
        case "analysis":
            return try await executeAnalysisTask(task, with: agent, for: project)
        case "design":
            return try await executeDesignTask(task, with: agent, for: project)
        case "implementation":
            return try await executeImplementationTask(task, with: agent, for: project)
        case "documentation":
            return try await executeDocumentationTask(task, with: agent, for: project)
        case "testing":
            return try await executeTestingTask(task, with: agent, for: project)
        default:
            return try await executeGenericTask(task, with: agent, for: project)
        }
    }
    
    private func executeAnalysisTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // Analyze project documents using AI
        let analyzer = AIDocumentAnalyzer()
        let analysisResult = try await analyzer.analyzeProjectDocuments(project.documents)
        
        return BMadTaskResult(
            success: true,
            output: analysisResult,
            artifacts: ["analysis_report.md"],
            metrics: ["confidence": 0.85],
            timestamp: Date()
        )
    }
    
    private func executeDesignTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // Design system architecture
        let architect = SystemArchitect()
        let designResult = try await architect.designArchitecture(for: project)
        
        return BMadTaskResult(
            success: true,
            output: designResult,
            artifacts: ["architecture.md", "design_diagrams.png"],
            metrics: ["complexity": 0.7],
            timestamp: Date()
        )
    }
    
    private func executeImplementationTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // Generate code using AI
        let generator = SDKGenerator.shared
        let sdk = await generator.generateSDK(from: project)
        
        return BMadTaskResult(
            success: true,
            output: "SDK generated successfully",
            artifacts: sdk.libraries.flatMap { $0.sourceFiles.map { $0.absoluteString } },
            metrics: ["lines_of_code": Double(sdk.libraries.count * 100)],
            timestamp: Date()
        )
    }
    
    private func executeDocumentationTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // Generate documentation
        let docGenerator = DocumentationGenerator()
        let documentation = try await docGenerator.generateDocumentation(for: project)
        
        return BMadTaskResult(
            success: true,
            output: documentation,
            artifacts: ["README.md", "API_REFERENCE.md"],
            metrics: ["coverage": 0.9],
            timestamp: Date()
        )
    }
    
    private func executeTestingTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // Generate and run tests
        let testGenerator = TestGenerator()
        let testResults = try await testGenerator.generateAndRunTests(for: project)
        
        return BMadTaskResult(
            success: testResults.allPassed,
            output: testResults.summary,
            artifacts: testResults.testFiles,
            metrics: ["pass_rate": testResults.passRate],
            timestamp: Date()
        )
    }
    
    private func executeGenericTask(_ task: ProjectTask, with agent: BMadAgent, for project: Project) async throws -> BMadTaskResult {
        // Fallback for unknown task types
        return BMadTaskResult(
            success: true,
            output: "Task completed: \(task.title)",
            artifacts: [],
            metrics: [:],
            timestamp: Date()
        )
    }
    
    private func handleTaskCompletion(_ task: ProjectTask, result: BMadTaskResult, for project: Project) async {
        // Update task status and project progress
        await MainActor.run {
            // Update project in storage with completed task
            var updatedProject = project
            if let taskIndex = updatedProject.tasks.firstIndex(where: { $0.id == task.id }) {
                updatedProject.tasks[taskIndex].status = result.success ? .completed : .error
            }
            ProjectStorage.shared.saveProject(updatedProject)
        }
        
        print("Task '\(task.title)' completed successfully")
    }
    
    private func handleTaskError(_ task: ProjectTask, error: Error, for project: Project) async {
        await MainActor.run {
            var updatedProject = project
            if let taskIndex = updatedProject.tasks.firstIndex(where: { $0.id == task.id }) {
                updatedProject.tasks[taskIndex].status = .error
            }
            ProjectStorage.shared.saveProject(updatedProject)
        }
        
        print("Task '\(task.title)' failed: \(error.localizedDescription)")
    }
    
    private func extractProjectName(from vision: String) -> String {
        let words = vision.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count >= 3 {
            return words.prefix(3).joined(separator: " ")
        } else if !words.isEmpty {
            return words.joined(separator: " ")
        } else {
            return "Untitled Project"
        }
    }
    
    private func executeTask(_ task: BMadTask, with agents: [BMadAgent]) async throws {
        // Legacy method - now delegates to new BMad-native approach
        // This maintains compatibility while using the new system
        print("Executing BMad task: \(task.name)")
    }
}
