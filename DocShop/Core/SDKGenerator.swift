import Foundation

class SDKGenerator {
    static let shared = SDKGenerator()
    
    private init() {}
    
    func generateSDK(from project: Project) async -> GeneratedSDK {
        // Extract API specifications from project documents
        let apiSpec = await extractAPISpecifications(from: project.documents)
        // Generate client libraries for all supported languages
        var libraries: [ClientLibrary] = []
        for lang in ProgrammingLanguage.allCases {
            let lib = await generateClientLibrary(for: apiSpec, language: lang)
            libraries.append(lib)
        }
        // Generate documentation and tests (stubbed for now)
        let documentation = "# SDK Documentation\n\nGenerated for project \(project.name)"
        let tests = ["// TODO: Add language-specific tests"]
        // Package SDK (stub: no real packaging yet)
        let packageURL: URL? = nil
        return GeneratedSDK(libraries: libraries, documentation: documentation, tests: tests, packageURL: packageURL)
    }
    
    func extractAPISpecifications(from documents: [DocumentMetaData]) async -> APISpecification {
        var endpoints: [APIEndpoint] = []
        var dataModels: [APIDataModel] = []
        var authMethods: [String] = []
        
        // Read the contents of all documents
        let filePaths = documents.map { $0.filePath }
        let readResults = try? await readMultipleFiles(paths: filePaths)
        
        for doc in documents {
            guard let content = readResults?[doc.filePath] else {
                print("Failed to read document: \(doc.filePath)")
                continue
            }
            
            // Use regular expressions to find API specifications in code blocks
            if let openAPISpec = extractOpenAPISpec(from: content) {
                endpoints.append(contentsOf: openAPISpec.endpoints)
                dataModels.append(contentsOf: openAPISpec.dataModels)
                authMethods.append(contentsOf: openAPISpec.authMethods)
            }
        }
        return APISpecification(endpoints: endpoints, dataModels: dataModels, authMethods: authMethods)
    }
    
    // Helper function to read multiple files
    private func readMultipleFiles(paths: [String]) async throws -> [String: String] {
        var results: [String: String] = [:]
        for path in paths {
            do {
                let (data, _) = try await URLSession.shared.data(from: URL(fileURLWithPath: path))
                if let content = String(data: data, encoding: .utf8) {
                    results[path] = content
                } else {
                    print("Failed to decode content for file: \(path)")
                }
            } catch {
                print("Failed to read file: \(path) - \(error)")
            }
        }
        return results
    }
    
    // Helper function to extract OpenAPI specifications from Markdown content
    private func extractOpenAPISpec(from content: String) -> APISpecification? {
        // Regular expressions to find code blocks with JSON or YAML
        let jsonRegex = try? NSRegularExpression(pattern: "```json\\s*\\n(.*?)\\n\\s*```", options: .dotMatchesLineSeparators)
        let yamlRegex = try? NSRegularExpression(pattern: "```yaml\\s*\\n(.*?)\\n\\s*```", options: .dotMatchesLineSeparators)
        
        // Extract JSON code blocks
        if let jsonMatch = jsonRegex?.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) {
            if let jsonRange = Range(jsonMatch.range(at: 1), in: content) {
                let jsonString = String(content[jsonRange])
                // TODO: Implement proper JSON parsing and extract API specifications
                print("Found JSON OpenAPI spec:\n\(jsonString)")
            }
        }
        
        // Extract YAML code blocks
        if let yamlMatch = yamlRegex?.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) {
            if let yamlRange = Range(yamlMatch.range(at: 1), in: content) {
                let yamlString = String(content[yamlRange])
                // TODO: Implement proper YAML parsing and extract API specifications
                print("Found YAML OpenAPI spec:\n\(yamlString)")
            }
        }
        
        return nil
    }
    
    func generateClientLibrary(for spec: APISpecification, language: ProgrammingLanguage) async -> ClientLibrary {
        // Generate language-specific client code, docs, examples (stub: create placeholder source file URLs)
        let doc = "# \(language.rawValue.capitalized) SDK\n\nAuto-generated client for API."
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(language.rawValue)_client_stub.swift")
        try? "// \(language.rawValue.capitalized) client stub".write(to: fileURL, atomically: true, encoding: .utf8)
        return ClientLibrary(language: language, sourceFiles: [fileURL], documentation: doc)
    }
}

// MARK: - Supporting Types

struct GeneratedSDK {
    let libraries: [ClientLibrary]
    let documentation: String
    let tests: [String]
    let packageURL: URL?
}

struct APISpecification {
    let endpoints: [APIEndpoint]
    let dataModels: [APIDataModel]
    let authMethods: [String]
}

struct APIEndpoint {
    let path: String
    let method: String
    let parameters: [String]
    let responseSchema: String
}

struct APIDataModel {
    let name: String
    let properties: [String: String]
}

struct ClientLibrary {
    let language: ProgrammingLanguage
    let sourceFiles: [URL]
    let documentation: String
}

enum ProgrammingLanguage: String, Codable, CaseIterable, Identifiable {
    case swift, python, javascript, typescript, java, kotlin, go, ruby, csharp
    
    var id: Self { self }
}
