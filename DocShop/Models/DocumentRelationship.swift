import Foundation

// Enhanced DocumentRelationship model for improved document relationships
struct DocumentRelationship: Identifiable, Codable, Hashable {
    let id: UUID
    let sourceDocumentId: UUID
    let targetDocumentId: UUID
    let relationshipType: RelationshipType
    var strength: Float // 0.0 to 1.0 indicating relationship strength
    var metadata: [String: String]?
    let createdAt: Date
    var lastVerified: Date?
    var confidence: Float // 0.0 to 1.0 indicating confidence in the relationship
    var bidirectional: Bool // Whether the relationship applies in both directions
    var userVerified: Bool // Whether a user has manually verified this relationship
    var notes: String? // Optional notes about the relationship
    
    // Enhanced relationship types
    enum RelationshipType: String, Codable, CaseIterable {
        case reference // Document references another document
        case continuation // Document continues from another document
        case prerequisite // Document is a prerequisite for understanding another
        case similar // Documents cover similar topics
        case contradicts // Documents contain contradictory information
        case updates // Document updates information in another document
        case explains // Document explains concepts from another document
        case implements // Document implements ideas from another document
        case example // Document provides examples for another document
        case alternative // Document provides alternative approaches to another
        case related // General relationship without specific type
    }
    
    // Create a basic relationship
    init(sourceDocumentId: UUID, targetDocumentId: UUID, relationshipType: RelationshipType) {
        self.id = UUID()
        self.sourceDocumentId = sourceDocumentId
        self.targetDocumentId = targetDocumentId
        self.relationshipType = relationshipType
        self.strength = 1.0
        self.metadata = nil
        self.createdAt = Date()
        self.lastVerified = nil
        self.confidence = 1.0
        self.bidirectional = false
        self.userVerified = false
        self.notes = nil
    }
    
    // Create a detailed relationship
    init(
        sourceDocumentId: UUID,
        targetDocumentId: UUID,
        relationshipType: RelationshipType,
        strength: Float,
        metadata: [String: String]? = nil,
        bidirectional: Bool = false,
        confidence: Float = 1.0,
        userVerified: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.sourceDocumentId = sourceDocumentId
        self.targetDocumentId = targetDocumentId
        self.relationshipType = relationshipType
        self.strength = min(max(strength, 0.0), 1.0) // Ensure between 0 and 1
        self.metadata = metadata
        self.createdAt = Date()
        self.lastVerified = userVerified ? Date() : nil
        self.confidence = min(max(confidence, 0.0), 1.0) // Ensure between 0 and 1
        self.bidirectional = bidirectional
        self.userVerified = userVerified
        self.notes = notes
    }
    
    // Create the inverse relationship
    func inverse() -> DocumentRelationship {
        var inverseType: RelationshipType
        
        // Determine the appropriate inverse relationship type
        switch relationshipType {
        case .prerequisite:
            inverseType = .continuation
        case .continuation:
            inverseType = .prerequisite
        case .updates:
            inverseType = .reference
        case .contradicts:
            inverseType = .contradicts // Remains the same
        case .explains:
            inverseType = .reference
        case .implements:
            inverseType = .reference
        case .example:
            inverseType = .reference
        default:
            inverseType = .related
        }
        
        return DocumentRelationship(
            sourceDocumentId: targetDocumentId,
            targetDocumentId: sourceDocumentId,
            relationshipType: inverseType,
            strength: strength,
            metadata: metadata,
            bidirectional: bidirectional,
            confidence: confidence,
            userVerified: userVerified,
            notes: notes
        )
    }
    
    // Helper method to determine if this relationship is significant
    func isSignificant(threshold: Float = 0.5) -> Bool {
        return strength >= threshold && confidence >= threshold
    }
    
    // Helper method to create a verified version of this relationship
    func verified(by user: Bool = true, withNotes notes: String? = nil) -> DocumentRelationship {
        var updated = self
        updated.userVerified = user
        updated.lastVerified = Date()
        
        if let newNotes = notes {
            if let existingNotes = self.notes {
                updated.notes = existingNotes + "\n" + newNotes
            } else {
                updated.notes = newNotes
            }
        }
        
        return updated
    }
    
    // Helper method to update relationship strength
    func withStrength(_ newStrength: Float) -> DocumentRelationship {
        var updated = self
        updated.strength = min(max(newStrength, 0.0), 1.0)
        return updated
    }
    
    // Helper method to update relationship confidence
    func withConfidence(_ newConfidence: Float) -> DocumentRelationship {
        var updated = self
        updated.confidence = min(max(newConfidence, 0.0), 1.0)
        return updated
    }
    
    // Helper method to add metadata
    func withMetadata(_ key: String, _ value: String) -> DocumentRelationship {
        var updated = self
        var newMetadata = self.metadata ?? [:]
        newMetadata[key] = value
        updated.metadata = newMetadata
        return updated
    }
}

// Extension for relationship analysis
extension DocumentRelationship {
    // Calculate a composite score for the relationship
    var score: Float {
        return strength * confidence * (userVerified ? 1.2 : 1.0)
    }
    
    // Get a human-readable description of the relationship
    var description: String {
        let typeString = relationshipType.displayName
        let strengthDesc = strengthDescription
        let directionDesc = bidirectional ? "bidirectional" : "one-way"
        
        return "\(typeString) relationship (\(strengthDesc), \(directionDesc))"
    }
    
    // Get a description of the strength
    var strengthDescription: String {
        if strength > 0.8 {
            return "strong"
        } else if strength > 0.5 {
            return "moderate"
        } else {
            return "weak"
        }
    }
}

// Extension for relationship type display names
extension DocumentRelationship.RelationshipType {
    var displayName: String {
        switch self {
        case .reference:
            return "Reference"
        case .continuation:
            return "Continuation"
        case .prerequisite:
            return "Prerequisite"
        case .similar:
            return "Similar"
        case .contradicts:
            return "Contradictory"
        case .updates:
            return "Updates"
        case .explains:
            return "Explains"
        case .implements:
            return "Implements"
        case .example:
            return "Example"
        case .alternative:
            return "Alternative"
        case .related:
            return "Related"
        }
    }
}

// RelationshipManager for handling document relationships
class RelationshipManager {
    static let shared = RelationshipManager()
    
    private init() {}
    
    // Find all relationships for a document
    func findRelationships(for documentId: UUID, in relationships: [DocumentRelationship]) -> [DocumentRelationship] {
        return relationships.filter { 
            $0.sourceDocumentId == documentId || ($0.bidirectional && $0.targetDocumentId == documentId)
        }
    }
    
    // Find direct relationships between two documents
    func findDirectRelationships(between sourceId: UUID, and targetId: UUID, in relationships: [DocumentRelationship]) -> [DocumentRelationship] {
        return relationships.filter {
            ($0.sourceDocumentId == sourceId && $0.targetDocumentId == targetId) ||
            ($0.bidirectional && $0.sourceDocumentId == targetId && $0.targetDocumentId == sourceId)
        }
    }
    
    // Find the strongest relationship of a specific type
    func findStrongestRelationship(of type: DocumentRelationship.RelationshipType, for documentId: UUID, in relationships: [DocumentRelationship]) -> DocumentRelationship? {
        let filteredRelationships = relationships.filter {
            ($0.sourceDocumentId == documentId || ($0.bidirectional && $0.targetDocumentId == documentId)) &&
            $0.relationshipType == type
        }
        
        return filteredRelationships.max(by: { $0.strength < $1.strength })
    }
    
    // Create a bidirectional relationship between two documents
    func createBidirectionalRelationship(
        between sourceId: UUID,
        and targetId: UUID,
        type: DocumentRelationship.RelationshipType,
        strength: Float = 1.0
    ) -> [DocumentRelationship] {
        let forward = DocumentRelationship(
            sourceDocumentId: sourceId,
            targetDocumentId: targetId,
            relationshipType: type,
            strength: strength,
            bidirectional: true
        )
        
        let backward = DocumentRelationship(
            sourceDocumentId: targetId,
            targetDocumentId: sourceId,
            relationshipType: type,
            strength: strength,
            bidirectional: true
        )
        
        return [forward, backward]
    }
    
    // Merge relationships with the same source and target
    func mergeRelationships(_ relationships: [DocumentRelationship]) -> [DocumentRelationship] {
        var mergedDict: [String: DocumentRelationship] = [:]
        
        for relationship in relationships {
            let key = "\(relationship.sourceDocumentId)-\(relationship.targetDocumentId)-\(relationship.relationshipType.rawValue)"
            
            if let existing = mergedDict[key] {
                // Merge by taking the higher values
                let mergedStrength = max(existing.strength, relationship.strength)
                let mergedConfidence = max(existing.confidence, relationship.confidence)
                let mergedVerified = existing.userVerified || relationship.userVerified
                
                // Merge notes if both have them
                var mergedNotes: String? = existing.notes
                if let existingNotes = existing.notes, let newNotes = relationship.notes {
                    mergedNotes = existingNotes + "\n" + newNotes
                } else if relationship.notes != nil {
                    mergedNotes = relationship.notes
                }
                
                // Create merged relationship
                let merged = DocumentRelationship(
                    sourceDocumentId: existing.sourceDocumentId,
                    targetDocumentId: existing.targetDocumentId,
                    relationshipType: existing.relationshipType,
                    strength: mergedStrength,
                    metadata: existing.metadata, // Keep existing metadata
                    bidirectional: existing.bidirectional || relationship.bidirectional,
                    confidence: mergedConfidence,
                    userVerified: mergedVerified,
                    notes: mergedNotes
                )
                
                mergedDict[key] = merged
            } else {
                mergedDict[key] = relationship
            }
        }
        
        return Array(mergedDict.values)
    }
}
