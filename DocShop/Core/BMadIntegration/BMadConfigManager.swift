import Foundation
import Combine

/// Manages BMad configuration loading and parsing
class BMadConfigManager: ObservableObject {
    @Published var coreConfig: BMadCoreConfig?
    @Published var isLoaded: Bool = false
    
    private let bmadCorePath = ".bmad-core"
    private let configFileName = "core-config.yaml"
    
    func loadCoreConfig() {
        guard let configPath = getConfigPath() else {
            print("BMad core config path not found")
            return
        }
        
        do {
            let configData = try Data(contentsOf: configPath)
            guard let configString = String(data: configData, encoding: .utf8) else { return }
            
            // Parse YAML configuration
            let parsedConfig = try parseYAMLConfig(configString)
            
            DispatchQueue.main.async {
                self.coreConfig = parsedConfig
                self.isLoaded = true
            }
            
        } catch {
            print("Failed to load BMad config: \(error)")
        }
    }
    
    private func getConfigPath() -> URL? {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let configPath = URL(fileURLWithPath: currentDirectory)
            .appendingPathComponent(bmadCorePath)
            .appendingPathComponent(configFileName)
        
        return fileManager.fileExists(atPath: configPath.path) ? configPath : nil
    }
    
    private func parseYAMLConfig(_ yamlString: String) throws -> BMadCoreConfig {
        // For now, we'll create a basic config structure
        // In a real implementation, you'd use a YAML parser like Yams
        
        return BMadCoreConfig(
            version: "1.0.0",
            methodology: BMadMethodologyConfig(
                approach: "ai-powered-development",
                principles: [
                    "Iterative Development",
                    "Continuous Integration",
                    "Quality Assurance",
                    "Documentation-Driven"
                ],
                phases: [
                    "Analysis",
                    "Design", 
                    "Implementation",
                    "Testing",
                    "Review"
                ],
                qualityGates: [
                    "Code Review",
                    "Unit Tests",
                    "Integration Tests",
                    "Performance Tests"
                ]
            ),
            agents: BMadAgentsConfig(
                orchestrator: BMadAgentDefinition(
                    role: "orchestrator",
                    responsibilities: ["Workflow coordination", "Task distribution"],
                    capabilities: ["Multi-agent coordination", "Progress tracking"],
                    tools: ["Workflow engine", "Task scheduler"],
                    constraints: ["Resource limits", "Time constraints"]
                ),
                analyst: BMadAgentDefinition(
                    role: "analyst",
                    responsibilities: ["Requirements analysis", "System analysis"],
                    capabilities: ["Code analysis", "Architecture review"],
                    tools: ["Static analysis", "Dependency analysis"],
                    constraints: ["Analysis scope", "Time limits"]
                ),
                architect: BMadAgentDefinition(
                    role: "architect",
                    responsibilities: ["System design", "Architecture decisions"],
                    capabilities: ["Design patterns", "System architecture"],
                    tools: ["Design tools", "Architecture validation"],
                    constraints: ["Design principles", "System constraints"]
                ),
                developer: BMadAgentDefinition(
                    role: "developer",
                    responsibilities: ["Code implementation", "Feature development"],
                    capabilities: ["Code generation", "Refactoring"],
                    tools: ["IDE integration", "Code generators"],
                    constraints: ["Coding standards", "Performance requirements"]
                ),
                tester: BMadAgentDefinition(
                    role: "tester",
                    responsibilities: ["Test creation", "Quality assurance"],
                    capabilities: ["Test generation", "Test execution"],
                    tools: ["Testing frameworks", "Test runners"],
                    constraints: ["Test coverage", "Test quality"]
                ),
                reviewer: BMadAgentDefinition(
                    role: "reviewer",
                    responsibilities: ["Code review", "Quality validation"],
                    capabilities: ["Code review", "Quality metrics"],
                    tools: ["Review tools", "Quality analyzers"],
                    constraints: ["Review criteria", "Quality standards"]
                )
            ),
            workflows: BMadWorkflowsConfig(
                templates: ["greenfield-fullstack", "feature-enhancement"],
                customWorkflows: [],
                defaultPhases: ["analysis", "design", "implementation", "testing", "review"]
            ),
            integrations: BMadIntegrationsConfig(
                ide: BMadIDEIntegration(
                    enabled: true,
                    features: ["Code completion", "Error detection"],
                    shortcuts: ["cmd+shift+b": "build", "cmd+shift+t": "test"]
                ),
                vcs: BMadVCSIntegration(
                    enabled: true,
                    provider: "git",
                    branchStrategy: "feature-branch",
                    commitConventions: ["conventional-commits"]
                ),
                ci: BMadCIIntegration(
                    enabled: true,
                    provider: "github-actions",
                    triggers: ["push", "pull-request"],
                    stages: ["build", "test", "deploy"]
                )
            )
        )
    }
    
    func getWorkflowTemplate(_ templateName: String) -> BMadWorkflow? {
        // Load workflow template from .bmad-core/workflows/
        let workflowPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(bmadCorePath)
            .appendingPathComponent("workflows")
            .appendingPathComponent("\(templateName).yaml")
        
        guard FileManager.default.fileExists(atPath: workflowPath.path) else {
            return nil
        }
        
        // For now, return a basic workflow structure
        // In a real implementation, parse the YAML workflow definition
        return createDefaultWorkflow(templateName)
    }
    
    private func createDefaultWorkflow(_ name: String) -> BMadWorkflow {
        let phases = [
            BMadWorkflowPhase(
                name: "Analysis",
                description: "Analyze requirements and existing code",
                tasks: [
                    BMadTask(
                        name: "Code Analysis",
                        description: "Analyze existing codebase",
                        type: .analysis,
                        assignedAgent: "analyst",
                        inputs: [:],
                        outputs: [:]
                    )
                ],
                requiredAgents: ["analyst"],
                dependencies: []
            ),
            BMadWorkflowPhase(
                name: "Design",
                description: "Design system architecture and components",
                tasks: [
                    BMadTask(
                        name: "Architecture Design",
                        description: "Design system architecture",
                        type: .design,
                        assignedAgent: "architect",
                        inputs: [:],
                        outputs: [:]
                    )
                ],
                requiredAgents: ["architect"],
                dependencies: ["Analysis"]
            ),
            BMadWorkflowPhase(
                name: "Implementation",
                description: "Implement designed features",
                tasks: [
                    BMadTask(
                        name: "Feature Implementation",
                        description: "Implement core features",
                        type: .implementation,
                        assignedAgent: "developer",
                        inputs: [:],
                        outputs: [:]
                    )
                ],
                requiredAgents: ["developer"],
                dependencies: ["Design"]
            )
        ]
        
        return BMadWorkflow(
            name: name,
            type: .greenfieldFullstack,
            phases: phases,
            context: BMadContext(
                projectPath: FileManager.default.currentDirectoryPath,
                targetFiles: [],
                requirements: [],
                constraints: [],
                metadata: [:]
            ),
            metadata: BMadMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                version: "1.0.0",
                author: "BMad System",
                tags: []
            )
        )
    }
}