import Foundation
import SwiftUI
import Combine

/// Integration service that connects BMad methodology with DocShop's existing functionality
class DocShopBMadIntegration: ObservableObject {
    @Published var integrationStatus: IntegrationStatus = .idle
    @Published var availableEnhancements: [DocShopEnhancement] = []
    
    private let orchestrator = BMadOrchestrator()
    private let documentProcessor = DocumentProcessor.shared
    private let library = DocLibraryIndex.shared
    
    enum IntegrationStatus {
        case idle
        case analyzing
        case planning
        case implementing
        case testing
        case completed
        case error(String)
    }
    
    init() {
        loadAvailableEnhancements()
    }
    
    func startDocShopEnhancement() async {
        integrationStatus = .analyzing
        
        // Create BMad context for DocShop enhancement
        let context = BMadContext(
            projectPath: FileManager.default.currentDirectoryPath,
            targetFiles: getDocShopCoreFiles(),
            requirements: getDocShopRequirements(),
            constraints: getDocShopConstraints(),
            metadata: [
                "project_type": "docshop_enhancement",
                "framework": "swiftui",
                "persistence": "coredata"
            ]
        )
        
        await orchestrator.startWorkflow(.featureEnhancement, context: context)
        integrationStatus = .completed
    }
    
    private func getDocShopCoreFiles() -> [String] {
        return [
            "DocShop/Core/DocumentProcessor.swift",
            "DocShop/Models/IngestedDocument.swift",
            "DocShop/Views/LibraryView.swift",
            "DocShop/Views/DocumentDetailView.swift",
            "DocShop/Core/DocumentStorage.swift",
            "DocShop/Core/DocLibraryIndex.swift"
        ]
    }
    
    private func getDocShopRequirements() -> [String] {
        return [
            "Implement comprehensive document search functionality",
            "Add document export capabilities (PDF, DOCX, HTML, Markdown)",
            "Enhance document processing pipeline with better error handling",
            "Implement document tagging and categorization system",
            "Add document version control and history tracking",
            "Improve user interface responsiveness and performance",
            "Implement document sharing and collaboration features",
            "Add advanced document filtering and sorting options",
            "Implement document templates and quick creation tools",
            "Add document analytics and usage tracking"
        ]
    }
    
    private func getDocShopConstraints() -> [String] {
        return [
            "Maintain SwiftUI compatibility and design patterns",
            "Preserve existing Core Data schema and relationships",
            "Ensure backward compatibility with existing documents",
            "Follow Apple's Human Interface Guidelines",
            "Maintain performance standards for large document libraries",
            "Preserve existing user preferences and settings",
            "Ensure data privacy and security compliance",
            "Maintain cross-platform compatibility (macOS focus)"
        ]
    }
    
    private func loadAvailableEnhancements() {
        availableEnhancements = [
            DocShopEnhancement(
                id: UUID(),
                name: "Advanced Search System",
                description: "Implement full-text search with filters, tags, and metadata search",
                priority: .high,
                estimatedEffort: .medium,
                targetFiles: ["DocShop/Core/SearchEngine.swift", "DocShop/Views/SearchView.swift"],
                dependencies: []
            ),
            DocShopEnhancement(
                id: UUID(),
                name: "Document Export System",
                description: "Add export capabilities for multiple formats",
                priority: .high,
                estimatedEffort: .large,
                targetFiles: ["DocShop/Core/ExportEngine.swift", "DocShop/Views/ExportView.swift"],
                dependencies: []
            ),
            DocShopEnhancement(
                id: UUID(),
                name: "Document Tagging System",
                description: "Implement tagging and categorization for better organization",
                priority: .medium,
                estimatedEffort: .medium,
                targetFiles: ["DocShop/Models/DocumentTag.swift", "DocShop/Views/TaggingView.swift"],
                dependencies: []
            ),
            DocShopEnhancement(
                id: UUID(),
                name: "Enhanced Document Processing",
                description: "Improve document processing with better error handling and progress tracking",
                priority: .high,
                estimatedEffort: .medium,
                targetFiles: ["DocShop/Core/DocumentProcessor.swift"],
                dependencies: []
            ),
            DocShopEnhancement(
                id: UUID(),
                name: "Document Version Control",
                description: "Track document changes and maintain version history",
                priority: .medium,
                estimatedEffort: .large,
                targetFiles: ["DocShop/Core/VersionControl.swift", "DocShop/Models/DocumentVersion.swift"],
                dependencies: ["Document Tagging System"]
            )
        ]
    }
    
    func getEnhancementsByPriority() -> [DocShopEnhancement] {
        return availableEnhancements.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.estimatedEffort.weight < rhs.estimatedEffort.weight
            }
            return lhs.priority.weight > rhs.priority.weight
        }
    }
    
    func startSpecificEnhancement(_ enhancement: DocShopEnhancement) async {
        integrationStatus = .planning
        
        let context = BMadContext(
            projectPath: FileManager.default.currentDirectoryPath,
            targetFiles: enhancement.targetFiles,
            requirements: [enhancement.description],
            constraints: getDocShopConstraints(),
            metadata: [
                "enhancement_id": enhancement.id.uuidString,
                "enhancement_name": enhancement.name,
                "priority": String(enhancement.priority.weight),
                "effort": String(enhancement.estimatedEffort.weight)
            ]
        )
        
        await orchestrator.startWorkflow(.featureEnhancement, context: context)
        integrationStatus = .completed
    }
    
    func analyzeCurrentDocShopState() -> DocShopAnalysis {
        let totalDocuments = library.documents.count
        let processingQueueSize = documentProcessor.processingQueue.count
        let isProcessing = documentProcessor.isProcessing
        
        // Analyze missing functionality based on our previous analysis
        let missingFeatures = [
            "Advanced search functionality",
            "Document export system",
            "Tagging and categorization",
            "Version control",
            "Collaboration features",
            "Analytics and reporting",
            "Template system",
            "Batch operations"
        ]
        
        let implementedFeatures = [
            "Basic document import",
            "Document storage",
            "Simple document viewing",
            "Basic library management",
            "Settings management"
        ]
        
        return DocShopAnalysis(
            totalDocuments: totalDocuments,
            processingQueueSize: processingQueueSize,
            isProcessing: isProcessing,
            implementedFeatures: implementedFeatures,
            missingFeatures: missingFeatures,
            functionalityCompleteness: 0.3, // 30% based on our previous analysis
            recommendedEnhancements: getEnhancementsByPriority().prefix(3).map { $0 }
        )
    }
}

// MARK: - Supporting Models

struct DocShopEnhancement: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let priority: Priority
    let estimatedEffort: Effort
    let targetFiles: [String]
    let dependencies: [String]
    
    enum Priority: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var weight: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    enum Effort: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extra_large"
        
        var weight: Int {
            switch self {
            case .small: return 1
            case .medium: return 2
            case .large: return 3
            case .extraLarge: return 4
            }
        }
        
        var displayName: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            case .extraLarge: return "Extra Large"
            }
        }
    }
}

struct DocShopAnalysis {
    let totalDocuments: Int
    let processingQueueSize: Int
    let isProcessing: Bool
    let implementedFeatures: [String]
    let missingFeatures: [String]
    let functionalityCompleteness: Double
    let recommendedEnhancements: [DocShopEnhancement]
    
    var completenessPercentage: Int {
        Int(functionalityCompleteness * 100)
    }
}

