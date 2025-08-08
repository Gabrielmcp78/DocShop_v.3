import XCTest

class ProjectRelationshipTests: XCTestCase {
    
    // Test document relationship creation
    func testDocumentRelationshipCreation() {
        let sourceId = UUID()
        let targetId = UUID()
        
        // Test basic relationship creation
        let basicRelationship = DocumentRelationship(
            sourceDocumentId: sourceId,
            targetDocumentId: targetId,
            relationshipType: .reference
        )
        
        XCTAssertEqual(basicRelationship.sourceDocumentId, sourceId)
        XCTAssertEqual(basicRelationship.targetDocumentId, targetId)
        XCTAssertEqual(basicRelationship.relationshipType, .reference)
        XCTAssertEqual(basicRelationship.strength, 1.0)
        XCTAssertFalse(basicRelationship.bidirectional)
        
        // Test detailed relationship creation
        let detailedRelationship = DocumentRelationship(
            sourceDocumentId: sourceId,
            targetDocumentId: targetId,
            relationshipType: .prerequisite,
            strength: 0.8,
            metadata: ["key": "value"],
            bidirectional: true,
            confidence: 0.9,
            userVerified: true,
            notes: "Test notes"
        )
        
        XCTAssertEqual(detailedRelationship.sourceDocumentId, sourceId)
        XCTAssertEqual(detailedRelationship.targetDocumentId, targetId)
        XCTAssertEqual(detailedRelationship.relationshipType, .prerequisite)
        XCTAssertEqual(detailedRelationship.strength, 0.8)
        XCTAssertEqual(detailedRelationship.metadata?["key"], "value")
        XCTAssertTrue(detailedRelationship.bidirectional)
        XCTAssertEqual(detailedRelationship.confidence, 0.9)
        XCTAssertTrue(detailedRelationship.userVerified)
        XCTAssertEqual(detailedRelationship.notes, "Test notes")
    }
    
    // Test relationship inverse creation
    func testRelationshipInverse() {
        let sourceId = UUID()
        let targetId = UUID()
        
        let relationship = DocumentRelationship(
            sourceDocumentId: sourceId,
            targetDocumentId: targetId,
            relationshipType: .prerequisite,
            strength: 0.8,
            metadata: ["key": "value"],
            bidirectional: false,
            confidence: 0.9,
            userVerified: true,
            notes: "Test notes"
        )
        
        let inverse = relationship.inverse()
        
        XCTAssertEqual(inverse.sourceDocumentId, targetId)
        XCTAssertEqual(inverse.targetDocumentId, sourceId)
        XCTAssertEqual(inverse.relationshipType, .continuation) // Inverse of prerequisite
        XCTAssertEqual(inverse.strength, 0.8)
        XCTAssertEqual(inverse.metadata?["key"], "value")
        XCTAssertFalse(inverse.bidirectional)
        XCTAssertEqual(inverse.confidence, 0.9)
        XCTAssertTrue(inverse.userVerified)
        XCTAssertEqual(inverse.notes, "Test notes")
    }
    
    // Test relationship helper methods
    func testRelationshipHelperMethods() {
        let sourceId = UUID()
        let targetId = UUID()
        
        var relationship = DocumentRelationship(
            sourceDocumentId: sourceId,
            targetDocumentId: targetId,
            relationshipType: .reference,
            strength: 0.5
        )
        
        // Test isSignificant
        XCTAssertTrue(relationship.isSignificant(threshold: 0.5))
        XCTAssertFalse(relationship.isSignificant(threshold: 0.6))
        
        // Test withStrength
        relationship = relationship.withStrength(0.7)
        XCTAssertEqual(relationship.strength, 0.7)
        
        // Test withConfidence
        relationship = relationship.withConfidence(0.8)
        XCTAssertEqual(relationship.confidence, 0.8)
        
        // Test withMetadata
        relationship = relationship.withMetadata("testKey", "testValue")
        XCTAssertEqual(relationship.metadata?["testKey"], "testValue")
        
        // Test verified
        relationship = relationship.verified(withNotes: "Verification note")
        XCTAssertTrue(relationship.userVerified)
        XCTAssertNotNil(relationship.lastVerified)
        XCTAssertEqual(relationship.notes, "Verification note")
    }
    
    // Test relationship manager
    func testRelationshipManager() {
        let manager = RelationshipManager.shared
        let doc1 = UUID()
        let doc2 = UUID()
        let doc3 = UUID()
        
        // Create test relationships
        let rel1 = DocumentRelationship(
            sourceDocumentId: doc1,
            targetDocumentId: doc2,
            relationshipType: .reference,
            strength: 0.8
        )
        
        let rel2 = DocumentRelationship(
            sourceDocumentId: doc1,
            targetDocumentId: doc3,
            relationshipType: .prerequisite,
            strength: 0.6
        )
        
        let rel3 = DocumentRelationship(
            sourceDocumentId: doc2,
            targetDocumentId: doc1,
            relationshipType: .continuation,
            strength: 0.7
        )
        
        let relationships = [rel1, rel2, rel3]
        
        // Test findRelationships
        let doc1Relationships = manager.findRelationships(for: doc1, in: relationships)
        XCTAssertEqual(doc1Relationships.count, 3)
        
        // Test findDirectRelationships
        let directRelationships = manager.findDirectRelationships(between: doc1, and: doc2, in: relationships)
        XCTAssertEqual(directRelationships.count, 2)
        
        // Test findStrongestRelationship
        let strongestReference = manager.findStrongestRelationship(of: .reference, for: doc1, in: relationships)
        XCTAssertNotNil(strongestReference)
        XCTAssertEqual(strongestReference?.strength, 0.8)
        
        // Test createBidirectionalRelationship
        let bidirectionalRels = manager.createBidirectionalRelationship(between: doc1, and: doc3, type: .similar, strength: 0.9)
        XCTAssertEqual(bidirectionalRels.count, 2)
        XCTAssertTrue(bidirectionalRels[0].bidirectional)
        XCTAssertTrue(bidirectionalRels[1].bidirectional)
        XCTAssertEqual(bidirectionalRels[0].sourceDocumentId, doc1)
        XCTAssertEqual(bidirectionalRels[1].sourceDocumentId, doc3)
    }
    
    // Test project document relationship management
    func testProjectDocumentRelationships() {
        // Create test documents
        let doc1 = createTestDocument(title: "Document 1")
        let doc2 = createTestDocument(title: "Document 2")
        let doc3 = createTestDocument(title: "Document 3")
        
        // Create test project
        var project = createTestProject(name: "Test Project", documents: [doc1, doc2, doc3])
        
        // Test adding relationships
        let relationship1 = DocumentRelationship(
            sourceDocumentId: doc1.id,
            targetDocumentId: doc2.id,
            relationshipType: .prerequisite,
            strength: 0.8
        )
        
        let relationship2 = DocumentRelationship(
            sourceDocumentId: doc2.id,
            targetDocumentId: doc3.id,
            relationshipType: .continuation,
            strength: 0.7
        )
        
        project.addDocumentRelationship(relationship1)
        project.addDocumentRelationship(relationship2)
        
        XCTAssertEqual(project.documentRelationships.count, 2)
        
        // Test getting relationships for a document
        let doc1Relationships = project.relationshipsForDocument(doc1.id)
        XCTAssertEqual(doc1Relationships.count, 1)
        XCTAssertEqual(doc1Relationships[0].relationshipType, .prerequisite)
        
        // Test getting related documents
        let relatedToDocs = project.relatedDocuments(to: doc2.id)
        XCTAssertEqual(relatedToDocs.count, 2)
        
        // Test removing a relationship
        project.removeDocumentRelationship(relationship1.id)
        XCTAssertEqual(project.documentRelationships.count, 1)
        
        // Test removing a document and its relationships
        project.removeDocument(withId: doc2.id)
        XCTAssertEqual(project.documents.count, 2)
        XCTAssertEqual(project.documentRelationships.count, 0)
    }
    
    // Test project categories
    func testProjectCategories() {
        // Create test documents
        let doc1 = createTestDocument(title: "Document 1")
        let doc2 = createTestDocument(title: "Document 2")
        let doc3 = createTestDocument(title: "Document 3")
        
        // Create test project
        var project = createTestProject(name: "Test Project", documents: [doc1, doc2, doc3])
        
        // Test adding categories
        let category1 = DocumentCategory(name: "Category 1", description: "Test category 1")
        let category2 = DocumentCategory(name: "Category 2", description: "Test category 2")
        
        project.addCategory(category1)
        project.addCategory(category2)
        
        XCTAssertEqual(project.documentCategories.count, 2)
        
        // Test adding documents to categories
        project.addDocument(withId: doc1.id, toCategory: category1.id)
        project.addDocument(withId: doc2.id, toCategory: category1.id)
        project.addDocument(withId: doc3.id, toCategory: category2.id)
        
        // Test getting documents in a category
        let docsInCategory1 = project.documentsInCategory(category1.id)
        XCTAssertEqual(docsInCategory1.count, 2)
        
        // Test marking primary documents
        project.markAsPrimaryDocument(doc1.id)
        XCTAssertEqual(project.primaryDocuments.count, 1)
        XCTAssertEqual(project.primaryDocuments[0], doc1.id)
    }
    
    // Test project health metrics
    func testProjectHealthMetrics() {
        // Create test documents with varying quality
        let doc1 = createTestDocument(title: "Document 1", withSummary: true, withTags: true)
        let doc2 = createTestDocument(title: "Document 2", withSummary: false, withTags: true)
        let doc3 = createTestDocument(title: "Document 3", withSummary: true, withTags: false)
        
        // Create test project with documentation requirements
        var requirements = ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.authentication],
            documentationRequirements: [.apiReference, .gettingStarted, .tutorials],
            testingRequirements: [.unit],
            performanceBenchmarks: []
        )
        
        var project = createTestProject(name: "Test Project", documents: [doc1, doc2, doc3], requirements: requirements)
        
        // Add some tasks
        let task1 = ProjectTask(
            id: UUID(),
            title: "Task 1",
            description: "Test task 1",
            status: .completed,
            priority: .high,
            assignedAgentID: nil,
            benchmarks: [],
            context: TaskContext(info: "test"),
            projectID: project.id
        )
        
        let task2 = ProjectTask(
            id: UUID(),
            title: "Task 2",
            description: "Test task 2",
            status: .inProgress,
            priority: .medium,
            assignedAgentID: nil,
            benchmarks: [],
            context: TaskContext(info: "test"),
            projectID: project.id
        )
        
        project.tasks = [task1, task2]
        
        // Update health metrics
        project.updateHealthMetrics()
        
        XCTAssertNotNil(project.healthMetrics)
        XCTAssertEqual(project.healthMetrics?.documentationCoverage, 1.0) // 3 docs for 3 requirements
        XCTAssertGreaterThan(project.healthMetrics?.documentationQuality ?? 0, 0)
        XCTAssertGreaterThan(project.healthMetrics?.documentationFreshness ?? 0, 0)
        XCTAssertEqual(project.healthMetrics?.taskCompletion, 0.5) // 1 of 2 tasks completed
    }
    
    // Helper method to create test documents
    private func createTestDocument(title: String, withSummary: Bool = false, withTags: Bool = false) -> DocumentMetaData {
        var document = DocumentMetaData(
            title: title,
            sourceURL: "https://example.com/\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            filePath: "/tmp/\(title.lowercased().replacingOccurrences(of: " ", with: "-")).md",
            fileSize: 1024,
            contentType: .markdown
        )
        
        if withSummary {
            document.summary = "Summary for \(title)"
        }
        
        if withTags {
            document.tags = ["test", title.lowercased()]
        }
        
        return document
    }
    
    // Helper method to create test projects
    private func createTestProject(name: String, documents: [DocumentMetaData], requirements: ProjectRequirements? = nil) -> Project {
        let projectRequirements = requirements ?? ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.authentication],
            documentationRequirements: [],
            testingRequirements: [],
            performanceBenchmarks: []
        )
        
        return Project(
            name: name,
            description: "Test project description",
            requirements: projectRequirements,
            documents: documents
        )
    }
}

