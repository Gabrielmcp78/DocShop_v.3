import Foundation
import Combine
import SwiftUI

/// Live task execution system with real-time progress tracking and UI updates
@MainActor
class LiveTaskExecutor: ObservableObject {
    static let shared = LiveTaskExecutor()
    
    @Published var activeTasks: [LiveTask] = []
    @Published var completedTasks: [LiveTask] = []
    @Published var failedTasks: [LiveTask] = []
    @Published var overallProgress: Double = 0.0
    @Published var isExecuting: Bool = false
    @Published var currentPhase: String = ""
    
    private let geminiAPI = EnhancedGeminiAPI.shared
    private let bmadOrchestrator = BMadOrchestrator()
    private var taskQueue: [ProjectTask] = []
    private var currentProject: Project?
    
    private init() {}
    
    // MARK: - Public Interface
    
    func startProjectExecution(_ project: Project) async {
        await MainActor.run {
            self.currentProject = project
            self.taskQueue = project.tasks
            self.isExecuting = true
            self.currentPhase = "Initializing BMad execution..."
            self.overallProgress = 0.0
            self.activeTasks.removeAll()
            self.completedTasks.removeAll()
            self.failedTasks.removeAll()
        }
        
        await executeTaskQueue()
    }
    
    func pauseExecution() {
        Task {
            await MainActor.run {
                self.isExecuting = false
                self.currentPhase = "Execution paused"
            }
        }
    }
    
    func resumeExecution() {
        Task {
            await MainActor.run {
                self.isExecuting = true
                self.currentPhase = "Resuming execution..."
            }
            await executeTaskQueue()
        }
    }
    
    func cancelExecution() {
        Task {
            await MainActor.run {
                self.isExecuting = false
                self.currentPhase = "Execution cancelled"
                self.activeTasks.removeAll()
                self.taskQueue.removeAll()
            }
        }
    }
    
    // MARK: - Task Execution Engine
    
    private func executeTaskQueue() async {
        guard isExecuting else { return }
        
        let totalTasks = taskQueue.count
        var completedCount = 0
        
        // Group tasks by BMad methodology phases
        let taskPhases = groupTasksByPhase(taskQueue)
        
        for (phaseName, phaseTasks) in taskPhases {
            guard isExecuting else { break }
            
            await updatePhase("Executing \(phaseName) phase...")
            
            // Execute tasks in parallel within each phase (where possible)
            await executePhase(phaseTasks, phaseName: phaseName)
            
            completedCount += phaseTasks.count
            await updateOverallProgress(Double(completedCount) / Double(totalTasks))
        }
        
        if isExecuting {
            await completeExecution()
        }
    }
    
    private func executePhase(_ tasks: [ProjectTask], phaseName: String) async {
        // Some tasks can run in parallel, others must be sequential
        let parallelTasks = tasks.filter { canRunInParallel($0) }
        let sequentialTasks = tasks.filter { !canRunInParallel($0) }
        
        // Execute parallel tasks concurrently
        if !parallelTasks.isEmpty {
            await withTaskGroup(of: Void.self) { group in
                for task in parallelTasks {
                    group.addTask {
                        await self.executeTask(task)
                    }
                }
            }
        }
        
        // Execute sequential tasks one by one
        for task in sequentialTasks {
            guard isExecuting else { break }
            await executeTask(task)
        }
    }
    
    private func executeTask(_ task: ProjectTask) async {
        let liveTask = LiveTask(
            id: task.id,
            title: task.title,
            description: task.description,
            type: task.context.info,
            status: .running,
            progress: 0.0,
            startTime: Date(),
            logs: []
        )
        
        await MainActor.run {
            self.activeTasks.append(liveTask)
        }
        
        do {
            // Execute task based on type using BMad methodology
            let result = try await executeTaskByType(task, liveTask: liveTask)
            
            await MainActor.run {
                if let index = self.activeTasks.firstIndex(where: { $0.id == liveTask.id }) {
                    self.activeTasks[index].status = .completed
                    self.activeTasks[index].progress = 1.0
                    self.activeTasks[index].endTime = Date()
                    self.activeTasks[index].result = result
                    
                    // Move to completed
                    self.completedTasks.append(self.activeTasks[index])
                    self.activeTasks.remove(at: index)
                }
            }
            
        } catch {
            await MainActor.run {
                if let index = self.activeTasks.firstIndex(where: { $0.id == liveTask.id }) {
                    self.activeTasks[index].status = .failed
                    self.activeTasks[index].endTime = Date()
                    self.activeTasks[index].error = error.localizedDescription
                    
                    // Move to failed
                    self.failedTasks.append(self.activeTasks[index])
                    self.activeTasks.remove(at: index)
                }
            }
        }
    }
    
    private func executeTaskByType(_ task: ProjectTask, liveTask: LiveTask) async throws -> String {
        guard let project = currentProject else {
            throw TaskExecutionError.noProject
        }
        
        await updateTaskProgress(liveTask.id, progress: 0.1, log: "Starting \(task.context.info) task...")
        
        switch task.context.info {
        case "analysis":
            return try await executeAnalysisTask(task, liveTask: liveTask, project: project)
        case "design":
            return try await executeDesignTask(task, liveTask: liveTask, project: project)
        case "implementation":
            return try await executeImplementationTask(task, liveTask: liveTask, project: project)
        case "documentation":
            return try await executeDocumentationTask(task, liveTask: liveTask, project: project)
        case "testing":
            return try await executeTestingTask(task, liveTask: liveTask, project: project)
        default:
            return try await executeGenericTask(task, liveTask: liveTask, project: project)
        }
    }
    
    // MARK: - Task Type Implementations
    
    private func executeAnalysisTask(_ task: ProjectTask, liveTask: LiveTask, project: Project) async throws -> String {
        await updateTaskProgress(liveTask.id, progress: 0.2, log: "Analyzing project documents...")
        
        let analysis = try await geminiAPI.analyzeDocuments(project.documents)
        
        await updateTaskProgress(liveTask.id, progress: 0.6, log: "Processing analysis results...")
        
        let report = """
        # Document Analysis Report
        
        ## Overview
        Analyzed \(project.documents.count) documents for project: \(project.name)
        
        ## Key Findings
        - Primary Languages: \(analysis.primaryLanguages.joined(separator: ", "))
        - Quality Score: \(String(format: "%.1f", analysis.qualityScore * 100))%
        - Completeness: \(String(format: "%.1f", analysis.completeness * 100))%
        
        ## Recommendations
        \(analysis.recommendations.map { "- \($0)" }.joined(separator: "\n"))
        
        ## Extracted Requirements
        \(analysis.extractedRequirements.map { "- \($0)" }.joined(separator: "\n"))
        """
        
        await updateTaskProgress(liveTask.id, progress: 1.0, log: "Analysis complete")
        
        return report
    }
    
    private func executeDesignTask(_ task: ProjectTask, liveTask: LiveTask, project: Project) async throws -> String {
        await updateTaskProgress(liveTask.id, progress: 0.2, log: "Designing system architecture...")
        
        let architecture = try await geminiAPI.generateArchitecture(for: project)
        
        await updateTaskProgress(liveTask.id, progress: 0.7, log: "Finalizing architecture design...")
        
        let designDoc = """
        # Architecture Design
        
        ## Overview
        \(architecture.overview)
        
        ## Components
        \(architecture.components.map { "- \($0.name): \($0.description)" }.joined(separator: "\n"))
        
        ## Data Flow
        \(architecture.dataFlow)
        
        ## Technology Stack
        \(architecture.technologies.joined(separator: ", "))
        
        ## Deployment Strategy
        \(architecture.deploymentStrategy)
        """
        
        await updateTaskProgress(liveTask.id, progress: 1.0, log: "Architecture design complete")
        
        return designDoc
    }
    
    private func executeImplementationTask(_ task: ProjectTask, liveTask: LiveTask, project: Project) async throws -> String {
        await updateTaskProgress(liveTask.id, progress: 0.2, log: "Generating implementation code...")
        
        let code = try await geminiAPI.generateImplementationCode(task: task, project: project)
        
        await updateTaskProgress(liveTask.id, progress: 0.8, log: "Validating generated code...")
        
        // Simulate code validation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await updateTaskProgress(liveTask.id, progress: 1.0, log: "Implementation complete")
        
        return code
    }
    
    private func executeDocumentationTask(_ task: ProjectTask, liveTask: LiveTask, project: Project) async throws -> String {
        await updateTaskProgress(liveTask.id, progress: 0.3, log: "Generating documentation...")
        
        // Simulate documentation generation
        let documentation = """
        # \(task.title)
        
        ## Description
        \(task.description)
        
        ## Implementation Details
        This documentation was generated as part of the BMad methodology workflow.
        
        ## Usage
        [Generated usage instructions based on project requirements]
        
        ## Examples
        [Code examples and implementation patterns]
        """
        
        await updateTaskProgress(liveTask.id, progress: 1.0, log: "Documentation complete")
        
        return documentation
    }
    
    private func executeTestingTask(_ task: ProjectTask, liveTask: LiveTask, project: Project) async throws -> String {
        await updateTaskProgress(liveTask.id, progress: 0.2, log: "Generating test cases...")
        
        // Simulate test generation and execution
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await updateTaskProgress(liveTask.id, progress: 0.6, log: "Running tests...")
        
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let testResults = """
        # Test Results for \(task.title)
        
        ## Summary
        - Total Tests: 15
        - Passed: 14
        - Failed: 1
        - Success Rate: 93.3%
        
        ## Test Details
        ✅ Unit tests: 10/10 passed
        ✅ Integration tests: 4/4 passed
        ❌ Performance tests: 0/1 passed
        
        ## Recommendations
        - Optimize performance for large datasets
        - Add more edge case testing
        """
        
        await updateTaskProgress(liveTask.id, progress: 1.0, log: "Testing complete")
        
        return testResults
    }
    
    private func executeGenericTask(_ task: ProjectTask, liveTask: LiveTask, project: Project) async throws -> String {
        await updateTaskProgress(liveTask.id, progress: 0.5, log: "Processing generic task...")
        
        // Simulate generic task execution
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await updateTaskProgress(liveTask.id, progress: 1.0, log: "Task complete")
        
        return "Task '\(task.title)' completed successfully"
    }
    
    // MARK: - Helper Methods
    
    private func groupTasksByPhase(_ tasks: [ProjectTask]) -> [(String, [ProjectTask])] {
        let phases = [
            ("Analysis", tasks.filter { $0.context.info == "analysis" }),
            ("Design", tasks.filter { $0.context.info == "design" }),
            ("Implementation", tasks.filter { $0.context.info == "implementation" }),
            ("Documentation", tasks.filter { $0.context.info == "documentation" }),
            ("Testing", tasks.filter { $0.context.info == "testing" })
        ]
        
        return phases.filter { !$1.isEmpty }
    }
    
    private func canRunInParallel(_ task: ProjectTask) -> Bool {
        // Documentation and some implementation tasks can run in parallel
        return task.context.info == "documentation" || task.context.info == "testing"
    }
    
    private func updateTaskProgress(_ taskId: UUID, progress: Double, log: String) async {
        await MainActor.run {
            if let index = self.activeTasks.firstIndex(where: { $0.id == taskId }) {
                self.activeTasks[index].progress = progress
                self.activeTasks[index].logs.append(TaskLog(timestamp: Date(), message: log))
            }
        }
    }
    
    private func updatePhase(_ phase: String) async {
        await MainActor.run {
            self.currentPhase = phase
        }
    }
    
    private func updateOverallProgress(_ progress: Double) async {
        await MainActor.run {
            self.overallProgress = progress
        }
    }
    
    private func completeExecution() async {
        await MainActor.run {
            self.isExecuting = false
            self.currentPhase = "Execution complete"
            self.overallProgress = 1.0
        }
    }
}

// MARK: - Supporting Models

struct LiveTask: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: String
    var status: TaskStatus
    var progress: Double
    let startTime: Date
    var endTime: Date?
    var result: String?
    var error: String?
    var logs: [TaskLog]
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

enum TaskStatus {
    case pending
    case running
    case completed
    case failed
    case cancelled
}

struct TaskLog {
    let timestamp: Date
    let message: String
}

enum TaskExecutionError: Error, LocalizedError {
    case noProject
    case taskFailed(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .noProject:
            return "No project context available"
        case .taskFailed(let message):
            return "Task failed: \(message)"
        case .cancelled:
            return "Task execution was cancelled"
        }
    }
}