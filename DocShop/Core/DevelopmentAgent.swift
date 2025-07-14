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
                // Simulate progress
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                    self.progress = Double(i) / 10.0
                }
                
                guard let project = AgentOrchestrator.shared.project(for: task.projectID) else {
                    completion(TaskResult(success: false, output: "", error: "Project not found"))
                    return
                }
                
                let documentFilePaths = project.documents.map { $0.filePath }
                
                var apiSpec: APISpecification? = nil
                
                if let firstFilePath = documentFilePaths.first {
                    // Search for API specifications in the first document
                    let searchResult = try? await searchCode(path: firstFilePath, pattern: "```json\\s*\\n(.*?)\\n\\s*```")
                    
                    if let searchResult = searchResult, !searchResult.isEmpty {
                        // Extract API specifications from the search result
                        apiSpec = extractAPISpecificationsFromSearchResult(searchResult: searchResult)
                        print("Found API specifications in \(firstFilePath):\n\(String(describing: apiSpec)) ")
                    } else {
                        print("No API specifications found in \(firstFilePath)")
                    }
                }

                // Route to specialized engines based on task type
                let output: String
                switch task.context.info.lowercased() {
                case let info where info.contains("sdk_generation"):
                    //output = try await AIEngine().generateSDK(from: project) // Pass project
                    output = "Generating SDK for \(project.name)"
                case let info where info.contains("documentation"):
                    output = try await CodeGenerator().generateDocumentation(for: project) // Pass project
                case let info where info.contains("validate"):
                    output = try await CodeValidator().validate(project: project) // Pass project
                default:
                    // Replace with actual task execution logic based on task.context.info
                    output = "TODO: Implement real task execution for \(task.title)"
                }
                self.status = .completed
                self.progress = 1.0
                // TODO: Persist task result
                completion(TaskResult(success: true, output: output, error: nil))
            } catch {
                self.status = .error
                completion(TaskResult(success: false, output: "", error: error.localizedDescription))
            }
            self.currentTask = nil
        }
    }
    
    func searchCode(path: String, pattern: String) async throws -> String {
        let arguments = [
            "path": path,
            "pattern": pattern
        ]
        
        let result = try await useMcpTool(serverName: "desktop-commander", toolName: "search_code", arguments: arguments)
        
        return result
    }
    
    func useMcpTool(serverName: String, toolName: String, arguments: [String: Any]) async throws -> String {
        let mcpToolArguments: [String: Any] = [
            "path": arguments["path"] as! String,
            "pattern": arguments["pattern"] as! String
        ]
        
        
        let result = try await use_mcp_tool(serverName: serverName, toolName: toolName, arguments: mcpToolArguments)
        
        return result
    
    func extractAPISpecificationsFromSearchResult(searchResult: String) -> APISpecification? {
        var endpoints: [APIEndpoint] = []
        var dataModels: [APIDataModel] = []
        var authMethods: [String] = []
        
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
        let generatedSDK = await SDKGenerator.shared.generateSDK(from: project)
        return "AIEngine completed: Generating SDK for \(project.name)"
    }
}
class CodeGenerator {
    func generateDocumentation(for project: Project) async throws -> String {
        // Simulate code generation
        try await Task.sleep(nanoseconds: 300_000_000)
        return "CodeGenerator completed: Generating documentation for \(project.name)"
    }
}
class CodeValidator {
    func validate(project: Project) async throws -> String {
        // Simulate code validation
        try await Task.sleep(nanoseconds: 300_000_000)
        return "CodeValidator completed: Validating project \(project.name)"
    }
}
