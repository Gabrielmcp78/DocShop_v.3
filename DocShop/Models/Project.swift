import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var requirements: ProjectRequirements
    
    // Enhanced document relationships
    var documents: [DocumentMetaData]
    var documentRelationships: [DocumentRelationship]
    var documentCategories: [DocumentCategory]
    var primaryDocuments: [UUID] // IDs of the most important documents
    
    var agents: [UUID] // Store agent IDs
    var tasks: [ProjectTask]
    var benchmarks: [Benchmark]
    var status: ProjectStatus
    var createdAt: Date
    var lastModified: Date
    var estimatedCompletion: Date?
    
    // Enhanced project metadata
    var tags: [String]
    var owner: String?
    var collaborators: [String]?
    var visibility: ProjectVisibility
    var version: String
    var healthMetrics: ProjectHealthMetrics?
    
    // Extensibility support
    var customAttributes: [String: String]?
    
    init(name: String, description: String, requirements: ProjectRequirements, documents: [DocumentMetaData]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.requirements = requirements
        self.documents = documents
        self.documentRelationships = []
        self.documentCategories = []
        self.primaryDocuments = []
        self.agents = []
        self.tasks = []
        self.benchmarks = []
        self.status = .initialized
        self.createdAt = Date()
        self.lastModified = Date()
        self.estimatedCompletion = nil
        self.tags = []
        self.owner = nil
        self.collaborators = nil
        self.visibility = .private
        self.version = "1.0.0"
        self.healthMetrics = nil
        self.customAttributes = nil
    }
    
    // Enhanced constructor with more options
    init(
        name: String,
        description: String,
        requirements: ProjectRequirements,
        documents: [DocumentMetaData],
        tags: [String] = [],
        owner: String? = nil,
        visibility: ProjectVisibility = .private,
        version: String = "1.0.0"
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.requirements = requirements
        self.documents = documents
        self.documentRelationships = []
        self.documentCategories = []
        self.primaryDocuments = []
        self.agents = []
        self.tasks = []
        self.benchmarks = []
        self.status = .initialized
        self.createdAt = Date()
        self.lastModified = Date()
        self.estimatedCompletion = nil
        self.tags = tags
        self.owner = owner
        self.collaborators = nil
        self.visibility = visibility
        self.version = version
        self.healthMetrics = nil
        self.customAttributes = nil
    }
}

struct ProjectRequirements: Codable, Hashable, Equatable {
    var targetLanguages: [ProgrammingLanguage]
    var sdkFeatures: [SDKFeature]
    var documentationRequirements: [DocumentationType]
    var testingRequirements: [TestingType]
    var performanceBenchmarks: [BenchmarkCriteria]
    var projectName: String = ""
    var projectDescription: String = ""
}

struct ProjectTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var status: ProjectTaskStatus
    var priority: TaskPriority
    var assignedAgentID: UUID? // Store agent ID for Codable compliance
    var benchmarks: [Benchmark]
    var context: TaskContext
    let projectID: UUID
    
    static func generateInitialTasks(for project: Project) -> [ProjectTask] {
        var tasks: [ProjectTask] = []
        
        // Generate tasks based on requirements
        for language in project.requirements.targetLanguages {
            tasks.append(ProjectTask(
                id: UUID(),
                title: "Generate \(language.rawValue) SDK",
                description: "Create client library for \(language.rawValue)",
                status: .pending,
                priority: .high,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "sdk_generation"),
                projectID: project.id
            ))
        }
        
        // Add documentation tasks
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
        
        return tasks
    }
}

enum ProjectTaskStatus: String, Codable, Hashable, CaseIterable {
    case pending, assigned, inProgress, completed, blocked, error
}

struct Benchmark: Identifiable, Codable, Hashable, Equatable {
    static func == (lhs: Benchmark, rhs: Benchmark) -> Bool {
        return lhs.id == rhs.id && lhs.criteria == rhs.criteria && lhs.result == rhs.result
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(criteria)
        hasher.combine(result)
    }

    let id: UUID
    let criteria: BenchmarkCriteria
    var result: BenchmarkResult?
}

enum ProjectStatus: String, Codable, Hashable {
    case initialized, active, paused, completed, error
}

enum TaskPriority: String, Codable, Hashable, CaseIterable {
    case low, medium, high, critical
}

struct TaskContext: Codable, Hashable {
    let info: String // Placeholder for real context data
}

enum SDKFeature: String, Codable, Hashable, CaseIterable, Identifiable {
    case authentication, errorHandling, logging, asyncSupport, customEndpoints, codeExamples
    
    var id: Self { self }
}

enum DocumentationType: String, Codable, Hashable, CaseIterable, Identifiable {
    case apiReference, gettingStarted, tutorials, faq, changelog, architecture
    
    var id: Self { self }
}

enum TestingType: String, Codable, Hashable, CaseIterable, Identifiable {
    case unit, integration, e2e, performance, security
    
    var id: Self { self }
}

enum BenchmarkCriteria: String, Codable, Hashable, CaseIterable, Identifiable {
    var id: Self { self }
    case latency, throughput, correctness, codeQuality, docCompleteness, apiCompliance
} 
// Document category for organizing project documents
struct DocumentCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var documentIds: [UUID]
    var color: String? // Color code for UI representation
    var icon: String? // Icon name for UI representation
    var sortOrder: Int
    var parentCategoryId: UUID? // For hierarchical categories
    
    init(name: String, description: String? = nil, documentIds: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.documentIds = documentIds
        self.color = nil
        self.icon = nil
        self.sortOrder = 0
        self.parentCategoryId = nil
    }
}

// Project visibility settings
enum ProjectVisibility: String, Codable, Hashable {
    case `private` // Only visible to owner and collaborators
    case team // Visible to all team members
    case organization // Visible to entire organization
    case `public` // Visible to anyone
}

// Project health metrics
struct ProjectHealthMetrics: Codable, Hashable {
    var documentationCoverage: Float // 0.0 to 1.0
    var documentationQuality: Float // 0.0 to 1.0
    var documentationFreshness: Float // 0.0 to 1.0 (how up-to-date)
    var taskCompletion: Float // 0.0 to 1.0
    var lastUpdated: Date
    
    init() {
        self.documentationCoverage = 0.0
        self.documentationQuality = 0.0
        self.documentationFreshness = 0.0
        self.taskCompletion = 0.0
        self.lastUpdated = Date()
    }
}


// Extension for Project to add document relationship management
extension Project {
    // Add a document to the project
    mutating func addDocument(_ document: DocumentMetaData) {
        if !documents.contains(where: { $0.id == document.id }) {
            documents.append(document)
            lastModified = Date()
        }
    }
    
    // Remove a document from the project
    mutating func removeDocument(withId id: UUID) {
        documents.removeAll(where: { $0.id == id })
        documentRelationships.removeAll(where: { $0.sourceDocumentId == id || $0.targetDocumentId == id })
        primaryDocuments.removeAll(where: { $0 == id })
        
        // Update categories
        for i in 0..<documentCategories.count {
            documentCategories[i].documentIds.removeAll(where: { $0 == id })
        }
        
        lastModified = Date()
    }
    
    // Add a relationship between documents in the project
    mutating func addDocumentRelationship(_ relationship: DocumentRelationship) {
        // Ensure both documents are in the project
        guard 
            documents.contains(where: { $0.id == relationship.sourceDocumentId }),
            documents.contains(where: { $0.id == relationship.targetDocumentId })
        else {
            return
        }
        
        // Check if a similar relationship already exists
        if !documentRelationships.contains(where: { 
            $0.sourceDocumentId == relationship.sourceDocumentId && 
            $0.targetDocumentId == relationship.targetDocumentId &&
            $0.relationshipType == relationship.relationshipType
        }) {
            documentRelationships.append(relationship)
            lastModified = Date()
        }
    }
    
    // Remove a relationship
    mutating func removeDocumentRelationship(_ relationshipId: UUID) {
        documentRelationships.removeAll(where: { $0.id == relationshipId })
        lastModified = Date()
    }
    
    // Add a document category
    mutating func addCategory(_ category: DocumentCategory) {
        if !documentCategories.contains(where: { $0.id == category.id }) {
            documentCategories.append(category)
            lastModified = Date()
        }
    }
    
    // Add a document to a category
    mutating func addDocument(withId documentId: UUID, toCategory categoryId: UUID) {
        guard 
            documents.contains(where: { $0.id == documentId }),
            let categoryIndex = documentCategories.firstIndex(where: { $0.id == categoryId })
        else {
            return
        }
        
        if !documentCategories[categoryIndex].documentIds.contains(documentId) {
            documentCategories[categoryIndex].documentIds.append(documentId)
            lastModified = Date()
        }
    }
    
    // Mark a document as primary
    mutating func markAsPrimaryDocument(_ documentId: UUID) {
        guard documents.contains(where: { $0.id == documentId }) else {
            return
        }
        
        if !primaryDocuments.contains(documentId) {
            primaryDocuments.append(documentId)
            lastModified = Date()
        }
    }
    
    // Calculate and update health metrics
    mutating func updateHealthMetrics() {
        var metrics = ProjectHealthMetrics()
        
        // Calculate documentation coverage
        let totalRequiredDocs = requirements.documentationRequirements.count
        let completedDocs = documents.count
        metrics.documentationCoverage = totalRequiredDocs > 0 ? Float(min(completedDocs, totalRequiredDocs)) / Float(totalRequiredDocs) : 0.0
        
        // Calculate documentation quality (placeholder logic)
        let qualitySum = documents.reduce(0.0) { sum, doc in
            // Simple quality heuristic based on metadata completeness
            var quality = 0.0
            if doc.summary != nil { quality += 0.2 }
            if let tags = doc.tags, !tags.isEmpty { quality += 0.2 }
            if doc.language != nil { quality += 0.2 }
            if doc.dateLastAccessed != nil { quality += 0.2 }
            if doc.contentType != .unknown { quality += 0.2 }
            return sum + quality
        }
        metrics.documentationQuality = Float(
            documents.isEmpty ? 0.0 : Double(qualitySum) / Double(
                documents.count
            )
        )
        
        // Calculate documentation freshness
        let now = Date()
        let freshnessSum = documents.reduce(0.0) {
 sum,
 doc in
            if let modified = doc.dateModified {
                let daysSinceModified = Calendar.current.dateComponents(
                    [.day],
                    from: modified,
                    to: now
                ).day ?? 0
                // Freshness decreases with age (1.0 for today, 0.0 for 90+ days old)
                return sum + max(
                    0.0,
                    1.0 - (Double(Float(daysSinceModified)) / 90.0)
                )
            }
            return sum
        }
        metrics.documentationFreshness = documents.isEmpty ? 0.0 : Float(freshnessSum) / Float(documents.count)
        
        // Calculate task completion
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.status == .completed }.count
        metrics.taskCompletion = totalTasks > 0 ? Float(completedTasks) / Float(totalTasks) : 0.0
        
        metrics.lastUpdated = Date()
        self.healthMetrics = metrics
        self.lastModified = Date()
    }
    
    // Get all documents in a category
    func documentsInCategory(_ categoryId: UUID) -> [DocumentMetaData] {
        guard let category = documentCategories.first(where: { $0.id == categoryId }) else {
            return []
        }
        
        return documents.filter { document in
            category.documentIds.contains(document.id)
        }
    }
    
    // Get all relationships for a document
    func relationshipsForDocument(_ documentId: UUID) -> [DocumentRelationship] {
        return documentRelationships.filter {
            $0.sourceDocumentId == documentId || $0.targetDocumentId == documentId
        }
    }
    
    // Get related documents for a document
    func relatedDocuments(to documentId: UUID) -> [DocumentMetaData] {
        let relationships = relationshipsForDocument(documentId)
        let relatedIds = relationships.flatMap { relationship -> [UUID] in
            if relationship.sourceDocumentId == documentId {
                return [relationship.targetDocumentId]
            } else if relationship.targetDocumentId == documentId {
                return [relationship.sourceDocumentId]
            }
            return []
        }
        
        return documents.filter { document in
            relatedIds.contains(document.id)
        }
    }
}
