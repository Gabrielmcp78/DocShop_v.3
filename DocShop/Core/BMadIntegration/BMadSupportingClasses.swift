import Foundation

// MARK: - Supporting Classes for BMad Integration

class SystemArchitect {
    func designArchitecture(for project: Project) async throws -> String {
        var design = "# System Architecture Design\n\n"
        
        design += "## Project: \(project.name)\n"
        design += "\(project.description)\n\n"
        
        design += "## Architecture Overview\n"
        design += "Based on the project requirements, the following architecture is recommended:\n\n"
        
        // Analyze requirements and suggest architecture
        if project.requirements.targetLanguages.contains(.swift) {
            design += "### Swift Components\n"
            design += "- Native iOS/macOS application framework\n"
            design += "- SwiftUI for user interface\n"
            design += "- Combine for reactive programming\n\n"
        }
        
        if project.requirements.sdkFeatures.contains(.apiGeneration) {
            design += "### API Layer\n"
            design += "- RESTful API design\n"
            design += "- OpenAPI specification\n"
            design += "- Automatic client generation\n\n"
        }
        
        design += "### Data Layer\n"
        design += "- Document storage and indexing\n"
        design += "- Metadata management\n"
        design += "- Search and retrieval system\n\n"
        
        design += "### AI Integration\n"
        design += "- Document processing pipeline\n"
        design += "- Natural language understanding\n"
        design += "- Multi-agent coordination\n\n"
        
        // Simulate design time
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        return design
    }
}

class DocumentationGenerator {
    func generateDocumentation(for project: Project) async throws -> String {
        var documentation = "# \(project.name)\n\n"
        
        documentation += "\(project.description)\n\n"
        
        documentation += "## Overview\n"
        documentation += "This project was created using the BMad methodology, ensuring comprehensive documentation and testing.\n\n"
        
        documentation += "## Features\n"
        for feature in project.requirements.sdkFeatures {
            documentation += "- \(feature.rawValue.capitalized)\n"
        }
        documentation += "\n"
        
        documentation += "## Supported Languages\n"
        for language in project.requirements.targetLanguages {
            documentation += "- \(language.rawValue.capitalized)\n"
        }
        documentation += "\n"
        
        documentation += "## Documentation Types\n"
        for docType in project.requirements.documentationRequirements {
            documentation += "- \(docType.rawValue.capitalized)\n"
        }
        documentation += "\n"
        
        documentation += "## Testing\n"
        documentation += "This project includes the following testing approaches:\n"
        for testType in project.requirements.testingRequirements {
            documentation += "- \(testType.rawValue.capitalized) testing\n"
        }
        documentation += "\n"
        
        documentation += "## Getting Started\n"
        documentation += "1. Clone the repository\n"
        documentation += "2. Install dependencies\n"
        documentation += "3. Run the setup script\n"
        documentation += "4. Start developing!\n\n"
        
        documentation += "## Contributing\n"
        documentation += "Please read our contributing guidelines before submitting pull requests.\n\n"
        
        // Simulate generation time
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        return documentation
    }
}

class TestGenerator {
    struct TestResults {
        let allPassed: Bool
        let summary: String
        let testFiles: [String]
        let passRate: Double
    }
    
    func generateAndRunTests(for project: Project) async throws -> TestResults {
        var testFiles: [String] = []
        var passCount = 0
        var totalTests = 0
        
        // Generate tests based on requirements
        for testType in project.requirements.testingRequirements {
            let testFile = "\(testType.rawValue.capitalized)Tests.swift"
            testFiles.append(testFile)
            
            // Simulate test generation and execution
            let testsInFile = Int.random(in: 5...15)
            let passedInFile = Int.random(in: testsInFile-2...testsInFile)
            
            passCount += passedInFile
            totalTests += testsInFile
        }
        
        let passRate = totalTests > 0 ? Double(passCount) / Double(totalTests) : 0.0
        let allPassed = passCount == totalTests
        
        let summary = """
        # Test Results Summary
        
        Total Tests: \(totalTests)
        Passed: \(passCount)
        Failed: \(totalTests - passCount)
        Pass Rate: \(String(format: "%.1f", passRate * 100))%
        
        ## Test Files Generated
        \(testFiles.map { "- \($0)" }.joined(separator: "\n"))
        """
        
        // Simulate test execution time
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        return TestResults(
            allPassed: allPassed,
            summary: summary,
            testFiles: testFiles,
            passRate: passRate
        )
    }
}

// MARK: - BMad Agent Manager Extensions

extension BMadAgentManager {
    func assignAgentsForProject(_ project: Project) async -> [BMadAgent] {
        var assignedAgents: [BMadAgent] = []
        
        // Assign agents based on project requirements
        if !project.requirements.documentationRequirements.isEmpty {
            if let docAgent = availableAgents.first(where: { $0.role == "Documentation Specialist" }) {
                assignedAgents.append(docAgent)
            }
        }
        
        if !project.requirements.targetLanguages.isEmpty {
            if let devAgent = availableAgents.first(where: { $0.role == "Developer" }) {
                assignedAgents.append(devAgent)
            }
        }
        
        if !project.requirements.testingRequirements.isEmpty {
            if let testAgent = availableAgents.first(where: { $0.role == "QA Engineer" }) {
                assignedAgents.append(testAgent)
            }
        }
        
        // Always assign an architect for complex projects
        if project.requirements.sdkFeatures.count > 2 {
            if let architect = availableAgents.first(where: { $0.role == "Architect" }) {
                assignedAgents.append(architect)
            }
        }
        
        await MainActor.run {
            self.activeAgents = assignedAgents
        }
        
        return assignedAgents
    }
    
    func getAgentsForProject(_ project: Project) async -> [BMadAgent] {
        return activeAgents.filter { agent in
            project.agents.contains(agent.id)
        }
    }
}

// MARK: - Enhanced Enums

// Removed all invalid static lets for SDKFeature, DocumentationType, TestingType, and BenchmarkCriteria
