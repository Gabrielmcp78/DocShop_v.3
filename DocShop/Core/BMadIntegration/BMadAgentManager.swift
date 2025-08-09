import Foundation
import Combine

/// Manages BMad agents and their lifecycle
class BMadAgentManager: ObservableObject {
    @Published var availableAgents: [BMadAgent] = []
    @Published var activeAgents: [BMadAgent] = []
    
    private let bmadCorePath = ".bmad-core/agents"
    
    func loadAgents() {
        let agentDefinitions = loadAgentDefinitions()
        
        DispatchQueue.main.async {
            self.availableAgents = agentDefinitions.map { definition in
                BMadAgent(
                    name: definition.role,
                    role: definition.role,
                    capabilities: definition.capabilities,
                    specializations: definition.responsibilities,
                    configuration: BMadAgentConfig(
                        maxConcurrentTasks: 3,
                        timeoutSeconds: 300,
                        retryAttempts: 3,
                        parameters: [:]
                    )
                )
            }
        }
    }
    
    private func loadAgentDefinitions() -> [BMadAgentDefinition] {
        let fileManager = FileManager.default
        let agentsPath = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appendingPathComponent(bmadCorePath)
        
        guard fileManager.fileExists(atPath: agentsPath.path) else {
            return createDefaultAgentDefinitions()
        }
        
        // Load agent definitions from markdown files
        var definitions: [BMadAgentDefinition] = []
        
        do {
            let agentFiles = try fileManager.contentsOfDirectory(at: agentsPath, includingPropertiesForKeys: nil)
            
            for file in agentFiles where file.pathExtension == "md" {
                if let definition = parseAgentDefinition(from: file) {
                    definitions.append(definition)
                }
            }
        } catch {
            print("Failed to load agent definitions: \(error)")
            return createDefaultAgentDefinitions()
        }
        
        return definitions.isEmpty ? createDefaultAgentDefinitions() : definitions
    }
    
    private func parseAgentDefinition(from file: URL) -> BMadAgentDefinition? {
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            let fileName = file.deletingPathExtension().lastPathComponent
            
            // Extract role from filename (e.g., "bmad-analyst.md" -> "analyst")
            let role = fileName.replacingOccurrences(of: "bmad-", with: "")
            
            // Parse markdown content for agent definition
            // This is a simplified parser - in practice, you'd use a proper markdown parser
            let lines = content.components(separatedBy: .newlines)
            
            var responsibilities: [String] = []
            var capabilities: [String] = []
            var tools: [String] = []
            var constraints: [String] = []
            
            var currentSection = ""
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                if trimmedLine.hasPrefix("## ") {
                    currentSection = trimmedLine.replacingOccurrences(of: "## ", with: "").lowercased()
                } else if trimmedLine.hasPrefix("- ") {
                    let item = trimmedLine.replacingOccurrences(of: "- ", with: "")
                    
                    switch currentSection {
                    case "responsibilities":
                        responsibilities.append(item)
                    case "capabilities":
                        capabilities.append(item)
                    case "tools":
                        tools.append(item)
                    case "constraints":
                        constraints.append(item)
                    default:
                        break
                    }
                }
            }
            
            return BMadAgentDefinition(
                role: role,
                responsibilities: responsibilities,
                capabilities: capabilities,
                tools: tools,
                constraints: constraints
            )
            
        } catch {
            print("Failed to parse agent definition from \(file.path): \(error)")
            return nil
        }
    }
    
    private func createDefaultAgentDefinitions() -> [BMadAgentDefinition] {
        return [
            BMadAgentDefinition(
                role: "orchestrator",
                responsibilities: [
                    "Coordinate multi-agent workflows",
                    "Manage task distribution and scheduling",
                    "Monitor progress and handle escalations",
                    "Ensure quality gates are met"
                ],
                capabilities: [
                    "Workflow management",
                    "Task scheduling",
                    "Progress tracking",
                    "Resource allocation"
                ],
                tools: [
                    "Workflow engine",
                    "Task scheduler",
                    "Progress monitor",
                    "Resource manager"
                ],
                constraints: [
                    "Must maintain workflow integrity",
                    "Cannot exceed resource limits",
                    "Must respect task dependencies"
                ]
            ),
            BMadAgentDefinition(
                role: "analyst",
                responsibilities: [
                    "Analyze existing codebase and architecture",
                    "Identify technical debt and improvement opportunities",
                    "Assess system performance and scalability",
                    "Document findings and recommendations"
                ],
                capabilities: [
                    "Static code analysis",
                    "Architecture assessment",
                    "Performance analysis",
                    "Technical documentation"
                ],
                tools: [
                    "Code analyzers",
                    "Dependency trackers",
                    "Performance profilers",
                    "Documentation generators"
                ],
                constraints: [
                    "Analysis must be thorough and accurate",
                    "Must respect privacy and security requirements",
                    "Cannot modify existing code during analysis"
                ]
            ),
            BMadAgentDefinition(
                role: "architect",
                responsibilities: [
                    "Design system architecture and components",
                    "Define interfaces and data models",
                    "Ensure architectural consistency",
                    "Review and approve design decisions"
                ],
                capabilities: [
                    "System design",
                    "Architecture patterns",
                    "Interface design",
                    "Design validation"
                ],
                tools: [
                    "Design tools",
                    "Architecture validators",
                    "Pattern libraries",
                    "Interface generators"
                ],
                constraints: [
                    "Must follow established design principles",
                    "Cannot compromise system security",
                    "Must consider scalability and maintainability"
                ]
            ),
            BMadAgentDefinition(
                role: "developer",
                responsibilities: [
                    "Implement features according to specifications",
                    "Write clean, maintainable code",
                    "Follow coding standards and best practices",
                    "Integrate with existing systems"
                ],
                capabilities: [
                    "Code generation",
                    "Feature implementation",
                    "Code refactoring",
                    "System integration"
                ],
                tools: [
                    "Code generators",
                    "IDE integrations",
                    "Refactoring tools",
                    "Build systems"
                ],
                constraints: [
                    "Must follow coding standards",
                    "Cannot break existing functionality",
                    "Must include appropriate error handling"
                ]
            ),
            BMadAgentDefinition(
                role: "tester",
                responsibilities: [
                    "Create comprehensive test suites",
                    "Execute automated and manual tests",
                    "Validate system functionality and performance",
                    "Report and track defects"
                ],
                capabilities: [
                    "Test case generation",
                    "Automated testing",
                    "Performance testing",
                    "Defect tracking"
                ],
                tools: [
                    "Testing frameworks",
                    "Test runners",
                    "Performance monitors",
                    "Defect trackers"
                ],
                constraints: [
                    "Must achieve minimum test coverage",
                    "Cannot compromise test quality for speed",
                    "Must validate all critical paths"
                ]
            ),
            BMadAgentDefinition(
                role: "reviewer",
                responsibilities: [
                    "Review code for quality and standards compliance",
                    "Validate architectural decisions",
                    "Ensure security best practices",
                    "Approve or reject changes"
                ],
                capabilities: [
                    "Code review",
                    "Quality assessment",
                    "Security validation",
                    "Standards compliance"
                ],
                tools: [
                    "Code review tools",
                    "Quality analyzers",
                    "Security scanners",
                    "Compliance checkers"
                ],
                constraints: [
                    "Must maintain high quality standards",
                    "Cannot approve non-compliant code",
                    "Must provide constructive feedback"
                ]
            )
        ]
    }
    
    func getAgentsForPhase(_ phase: BMadWorkflowPhase) -> [BMadAgent] {
        return availableAgents.filter { agent in
            phase.requiredAgents.contains(agent.role)
        }
    }
    
    func activateAgent(_ agent: BMadAgent) {
        if let index = availableAgents.firstIndex(where: { $0.id == agent.id }) {
            availableAgents[index].isActive = true
            
            if !activeAgents.contains(where: { $0.id == agent.id }) {
                activeAgents.append(availableAgents[index])
            }
        }
    }
    
    func deactivateAgent(_ agent: BMadAgent) {
        if let index = availableAgents.firstIndex(where: { $0.id == agent.id }) {
            availableAgents[index].isActive = false
        }
        
        activeAgents.removeAll { $0.id == agent.id }
    }
    
    func getAgent(byRole role: String) -> BMadAgent? {
        return availableAgents.first { $0.role == role }
    }
}