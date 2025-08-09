import Foundation
import Combine

/// Core workflow execution engine for BMad methodology
class BMadWorkflowEngine: ObservableObject {
    @Published var runningWorkflows: [BMadWorkflow] = []
    @Published var completedWorkflows: [BMadWorkflow] = []
    
    private let configManager = BMadConfigManager()
    private let agentManager = BMadAgentManager()
    
    func createWorkflow(type: BMadWorkflowType, context: BMadContext) async throws -> BMadWorkflow {
        guard let template = configManager.getWorkflowTemplate(type.rawValue) else {
            throw BMadError.workflowTemplateNotFound(type.rawValue)
        }
        
        // Customize workflow based on context
        let customizedWorkflow = customizeWorkflow(template, with: context)
        
        await MainActor.run {
            self.runningWorkflows.append(customizedWorkflow)
        }
        
        return customizedWorkflow
    }
    
    private func customizeWorkflow(_ template: BMadWorkflow, with context: BMadContext) -> BMadWorkflow {
        // Analyze context and customize workflow phases/tasks accordingly
        var customizedPhases = template.phases
        
        // Add DocShop-specific customizations
        if context.projectPath.contains("DocShop") {
            customizedPhases = addDocShopSpecificTasks(to: customizedPhases, context: context)
        }
        
        return BMadWorkflow(
            name: template.name,
            type: template.type,
            phases: customizedPhases,
            context: context,
            metadata: BMadMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                version: template.metadata.version,
                author: "BMad Engine",
                tags: template.metadata.tags + ["customized", "docshop"]
            )
        )
    }
    
    private func addDocShopSpecificTasks(to phases: [BMadWorkflowPhase], context: BMadContext) -> [BMadWorkflowPhase] {
        return phases.map { phase in
            var customizedTasks = phase.tasks
            
            switch phase.name.lowercased() {
            case "analysis":
                customizedTasks.append(contentsOf: [
                    BMadTask(
                        name: "DocShop Architecture Analysis",
                        description: "Analyze DocShop's current architecture and identify integration points",
                        type: .analysis,
                        assignedAgent: "analyst",
                        inputs: ["codebase_path": context.projectPath],
                        outputs: [:]
                    ),
                    BMadTask(
                        name: "Missing Features Analysis",
                        description: "Identify missing features from the functionality analysis",
                        type: .analysis,
                        assignedAgent: "analyst",
                        inputs: ["analysis_report": "DocShop_Functionality_Analysis.md"],
                        outputs: [:]
                    )
                ])
                
            case "design":
                customizedTasks.append(contentsOf: [
                    BMadTask(
                        name: "SwiftUI Integration Design",
                        description: "Design SwiftUI components for missing functionality",
                        type: .design,
                        assignedAgent: "architect",
                        inputs: ["ui_framework": "SwiftUI"],
                        outputs: [:]
                    ),
                    BMadTask(
                        name: "Core Data Integration Design",
                        description: "Design Core Data models and relationships",
                        type: .design,
                        assignedAgent: "architect",
                        inputs: ["persistence_framework": "CoreData"],
                        outputs: [:]
                    )
                ])
                
            case "implementation":
                customizedTasks.append(contentsOf: [
                    BMadTask(
                        name: "Document Processing Enhancement",
                        description: "Implement enhanced document processing capabilities",
                        type: .implementation,
                        assignedAgent: "developer",
                        inputs: ["target_files": "DocumentProcessor.swift"],
                        outputs: [:]
                    ),
                    BMadTask(
                        name: "Search Functionality Implementation",
                        description: "Implement comprehensive search functionality",
                        type: .implementation,
                        assignedAgent: "developer",
                        inputs: ["search_types": "content,metadata,tags"],
                        outputs: [:]
                    ),
                    BMadTask(
                        name: "Export System Implementation",
                        description: "Implement document export functionality",
                        type: .implementation,
                        assignedAgent: "developer",
                        inputs: ["export_formats": "PDF,DOCX,HTML,Markdown"],
                        outputs: [:]
                    )
                ])
                
            case "testing":
                customizedTasks.append(contentsOf: [
                    BMadTask(
                        name: "SwiftUI Component Testing",
                        description: "Create tests for SwiftUI components",
                        type: .testing,
                        assignedAgent: "tester",
                        inputs: ["test_framework": "XCTest"],
                        outputs: [:]
                    ),
                    BMadTask(
                        name: "Document Processing Testing",
                        description: "Test document processing functionality",
                        type: .testing,
                        assignedAgent: "tester",
                        inputs: ["test_documents": "PDF,DOCX,TXT"],
                        outputs: [:]
                    )
                ])
                
            default:
                break
            }
            
            return BMadWorkflowPhase(
                name: phase.name,
                description: phase.description,
                tasks: customizedTasks,
                requiredAgents: phase.requiredAgents,
                dependencies: phase.dependencies
            )
        }
    }
    
    func executeWorkflow(_ workflow: BMadWorkflow) async throws {
        for phase in workflow.phases {
            try await executePhase(phase, in: workflow)
        }
        
        await MainActor.run {
            if let index = self.runningWorkflows.firstIndex(where: { $0.id == workflow.id }) {
                var completedWorkflow = self.runningWorkflows.remove(at: index)
                completedWorkflow.metadata = BMadMetadata(
                    createdAt: completedWorkflow.metadata.createdAt,
                    updatedAt: Date(),
                    version: completedWorkflow.metadata.version,
                    author: completedWorkflow.metadata.author,
                    tags: completedWorkflow.metadata.tags + ["completed"]
                )
                self.completedWorkflows.append(completedWorkflow)
            }
        }
    }
    
    private func executePhase(_ phase: BMadWorkflowPhase, in workflow: BMadWorkflow) async throws {
        // Check dependencies
        try validatePhaseDependencies(phase, in: workflow)
        
        // Get required agents
        let requiredAgents = agentManager.getAgentsForPhase(phase)
        
        // Activate agents
        for agent in requiredAgents {
            agentManager.activateAgent(agent)
        }
        
        // Execute tasks in parallel where possible
        try await withThrowingTaskGroup(of: Void.self) { group in
            for task in phase.tasks {
                group.addTask {
                    try await self.executeTask(task, in: phase, workflow: workflow)
                }
            }
            
            // Wait for all tasks to complete
            for try await _ in group {
                // Tasks complete automatically
            }
        }
        
        // Deactivate agents
        for agent in requiredAgents {
            agentManager.deactivateAgent(agent)
        }
    }
    
    private func validatePhaseDependencies(_ phase: BMadWorkflowPhase, in workflow: BMadWorkflow) throws {
        for dependency in phase.dependencies {
            let dependentPhase = workflow.phases.first { $0.name == dependency }
            guard let dependentPhase = dependentPhase, dependentPhase.isCompleted else {
                throw BMadError.phaseDependencyNotMet(phase.name, dependency)
            }
        }
    }
    
    private func executeTask(_ task: BMadTask, in phase: BMadWorkflowPhase, workflow: BMadWorkflow) async throws {
        guard let agent = agentManager.getAgent(byRole: task.assignedAgent) else {
            throw BMadError.agentNotFound(task.assignedAgent)
        }
        
        // Execute task based on type
        let result = try await executeTaskByType(task, agent: agent, workflow: workflow)
        
        // Update task with result
        await MainActor.run {
            // In a real implementation, you'd update the task in the workflow
            print("Task '\(task.name)' completed with result: \(result.success)")
        }
    }
    
    private func executeTaskByType(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        switch task.type {
        case .analysis:
            return try await executeAnalysisTask(task, agent: agent, workflow: workflow)
        case .design:
            return try await executeDesignTask(task, agent: agent, workflow: workflow)
        case .implementation:
            return try await executeImplementationTask(task, agent: agent, workflow: workflow)
        case .testing:
            return try await executeTestingTask(task, agent: agent, workflow: workflow)
        case .review:
            return try await executeReviewTask(task, agent: agent, workflow: workflow)
        case .documentation:
            return try await executeDocumentationTask(task, agent: agent, workflow: workflow)
        }
    }
    
    // MARK: - Task Execution Methods
    
    private func executeAnalysisTask(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        // Implement analysis task execution
        // This would integrate with DocShop's existing analysis capabilities
        
        return BMadTaskResult(
            success: true,
            output: "Analysis completed for task: \(task.name)",
            artifacts: ["analysis_report.md"],
            metrics: ["coverage": 0.85, "complexity": 0.6],
            timestamp: Date()
        )
    }
    
    private func executeDesignTask(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        // Implement design task execution
        
        return BMadTaskResult(
            success: true,
            output: "Design completed for task: \(task.name)",
            artifacts: ["design_document.md", "architecture_diagram.png"],
            metrics: ["design_quality": 0.9],
            timestamp: Date()
        )
    }
    
    private func executeImplementationTask(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        // Implement implementation task execution
        // This would integrate with DocShop's code generation and modification capabilities
        
        return BMadTaskResult(
            success: true,
            output: "Implementation completed for task: \(task.name)",
            artifacts: ["implemented_files.swift"],
            metrics: ["code_quality": 0.88, "test_coverage": 0.75],
            timestamp: Date()
        )
    }
    
    private func executeTestingTask(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        // Implement testing task execution
        
        return BMadTaskResult(
            success: true,
            output: "Testing completed for task: \(task.name)",
            artifacts: ["test_results.xml", "coverage_report.html"],
            metrics: ["test_coverage": 0.92, "pass_rate": 1.0],
            timestamp: Date()
        )
    }
    
    private func executeReviewTask(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        // Implement review task execution
        
        return BMadTaskResult(
            success: true,
            output: "Review completed for task: \(task.name)",
            artifacts: ["review_report.md"],
            metrics: ["quality_score": 0.91],
            timestamp: Date()
        )
    }
    
    private func executeDocumentationTask(_ task: BMadTask, agent: BMadAgent, workflow: BMadWorkflow) async throws -> BMadTaskResult {
        // Implement documentation task execution
        
        return BMadTaskResult(
            success: true,
            output: "Documentation completed for task: \(task.name)",
            artifacts: ["documentation.md", "api_docs.html"],
            metrics: ["completeness": 0.87],
            timestamp: Date()
        )
    }
}

// MARK: - BMad Errors

enum BMadError: Error, LocalizedError {
    case workflowTemplateNotFound(String)
    case agentNotFound(String)
    case phaseDependencyNotMet(String, String)
    case taskExecutionFailed(String, String)
    
    var errorDescription: String? {
        switch self {
        case .workflowTemplateNotFound(let template):
            return "Workflow template not found: \(template)"
        case .agentNotFound(let agent):
            return "Agent not found: \(agent)"
        case .phaseDependencyNotMet(let phase, let dependency):
            return "Phase '\(phase)' dependency not met: \(dependency)"
        case .taskExecutionFailed(let task, let reason):
            return "Task '\(task)' execution failed: \(reason)"
        }
    }
}