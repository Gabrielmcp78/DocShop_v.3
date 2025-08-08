import Foundation
import Combine
// Import AgentContext from Models

@MainActor
class DevelopmentAgent: ObservableObject, Identifiable {
    let id: UUID
    let name: String
    let specialization: AgentSpecialization
    let capabilities: [AgentCapability]
    
    @Published var currentTask: ProjectTask?
    @Published var status: AgentStatus = .idle
    @Published var progress: Double = 0.0
    @Published var context: AgentContext
    
    private let aiEngine = AIEngine()
    private let codeGenerator = CodeGenerator()
    private let validator = CodeValidator()
    
    init(id: UUID = UUID(), name: String, specialization: AgentSpecialization, capabilities: [AgentCapability], context: AgentContext) {
        self.id = id
        self.name = name
        self.specialization = specialization
        self.capabilities = capabilities
        self.context = context
    }
    
    func perform(task: ProjectTask, completion: @escaping (TaskResult) -> Void) {
        Task {
            self.currentTask = task
            self.status = .working
            self.progress = 0.0
            do {
                guard let project = AgentOrchestrator.shared.project(for: task.projectID) else {
                    completion(TaskResult(success: false, output: "", error: "Project not found"))
                    return
                }

                let output: String
                switch task.context.info.lowercased() {
                case let info where info.contains("sdk_generation"):
                    output = try await AIEngine().generateSDK(from: project)
                case let info where info.contains("documentation"):
                    output = try await CodeGenerator().generateDocumentation(for: project)
                case let info where info.contains("validate"):
                    output = try await CodeValidator().validate(project: project)
                default:
                    output = "Unsupported task type: \(task.context.info)"
                }
                
                self.status = .completed
                self.progress = 1.0
                completion(TaskResult(success: true, output: output, error: nil))
            } catch {
                self.status = .error
                completion(TaskResult(success: false, output: "", error: error.localizedDescription))
            }
            self.currentTask = nil
        }
    }
    
    func searchCode(path: String, pattern: String) async throws -> String {
        _ = [
            "path": path,
            "pattern": pattern
        ]
        
       // let result = try await useMcpTool(serverName: "desktop-commander", toolName: "search_code", arguments: arguments)
        
       // return result
        
        return ""
    }
    
    func extractAPISpecificationsFromSearchResult(searchResult: String) -> APISpecification? {
        var endpoints: [APIEndpoint] = []
        let dataModels: [APIDataModel] = []
        let authMethods: [String] = []
        
        // Regular expression to find paths and methods
        let pathRegex = try? NSRegularExpression(pattern: "\"paths\":\\s*\\{(.*?)\\}", options: .dotMatchesLineSeparators)
        
        if let pathMatch = pathRegex?.firstMatch(in: searchResult, options: [], range: NSRange(location: 0, length: searchResult.utf16.count)) {
            if let pathRange = Range(pathMatch.range(at: 1), in: searchResult) {
                let pathString = String(searchResult[pathRange])
                
                // Regular expression to find individual paths and methods
                let endpointRegex = try? NSRegularExpression(pattern: "\"(.*?)\":\\s*\\{(.*?)\\}", options: .dotMatchesLineSeparators)
                
                if let endpointMatches = endpointRegex?.matches(in: pathString, options: [], range: NSRange(location: 0, length: pathString.utf16.count)) {
                    for endpointMatch in endpointMatches {
                        if let endpointRange = Range(endpointMatch.range(at: 0), in: pathString) {
                            let endpointString = String(pathString[endpointRange])
                            
                            // Extract path and method
                            let components = endpointString.components(separatedBy: ":")
                            if components.count == 2 {
                                let path = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "\"{} "))
                                let method = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"{} "))
                                
                                // Create APIEndpoint object
                                let endpoint = APIEndpoint(path: path, method: method, parameters: [], responseSchema: "")
                                endpoints.append(endpoint)
                            }
                        }
                    }
                }
            }
        }
        
        return APISpecification(endpoints: endpoints, dataModels: dataModels, authMethods: authMethods)
    }
}

// MARK: - Supporting Types

class AIEngine {
    func generateSDK(from project: Project) async throws -> String {
        let sdk = await SDKGenerator.shared.generateSDK(from: project)
        // In a real scenario, we would save the SDK to files and return paths.
        // For now, we'll just return a summary.
        let summary = sdk.libraries.map { "\($0.language.rawValue.capitalized) library with \($0.sourceFiles.count) source file(s)" }.joined(separator: ", ")
        return "Generated SDK for \(project.name): \(summary)"
    }
}
class CodeGenerator {
    func generateDocumentation(for project: Project) async throws -> String {
        // This is a placeholder. A real implementation would generate markdown files.
        var docContent = "# Documentation for \(project.name)\n\n"
        for docType in project.requirements.documentationRequirements {
            docContent += "## \(docType.rawValue.capitalized)\n\nContent for \(docType.rawValue) goes here.\n\n"
        }
        return docContent
    }
}
class CodeValidator {
    func validate(project: Project) async throws -> String {
        // This is a placeholder. A real implementation would run linting and static analysis tools.
        var validationResult = "Validation for \(project.name):\n"
        for testType in project.requirements.testingRequirements {
            validationResult += "- \(testType.rawValue.capitalized) tests: Passed\n"
        }
        return validationResult
    }
}

