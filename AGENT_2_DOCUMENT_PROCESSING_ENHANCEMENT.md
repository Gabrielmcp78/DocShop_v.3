# Agent 2: Document Processing & Content Enhancement

## Agent Focus: Advanced Document Processing, Metadata Extraction, and Content Intelligence

### System Main Prompt
You are the **Document Processing Specialist Agent** responsible for enhancing DocShop's document processing capabilities to extract rich metadata, improve content analysis, and implement advanced document intelligence features.

### Core Mission
Transform the basic document import system into an intelligent content processing engine that extracts comprehensive metadata, creates semantic relationships, and enables advanced search and categorization.

## Implementation Tasks

### 1. Implement Advanced Metadata Extraction (CRITICAL - Week 1)

#### Current Issue
Documents are imported with minimal metadata. No framework detection, company identification, or topic categorization.

#### Implementation Required

#### Files to Modify
- `DocShop/Core/DocumentProcessor.swift` - Enhance `processDocument()`
- `DocShop/Models/DocumentMetaData.swift` - Add metadata fields
- `DocShop/Core/MetadataExtractor.swift` (CREATE)

#### Implementation Details
```swift
class MetadataExtractor {
    static let shared = MetadataExtractor()
    
    func extractComprehensiveMetadata(from content: String, url: URL) async -> DocumentMetadata {
        var metadata = DocumentMetadata()
        
        // Extract framework information
        metadata.framework = detectFramework(content)
        metadata.language = detectProgrammingLanguage(content)
        metadata.company = extractCompanyInfo(url, content)
        metadata.topics = extractTopics(content)
        metadata.apiEndpoints = extractAPIEndpoints(content)
        metadata.codeExamples = extractCodeExamples(content)
        
        return metadata
    }
    
    private func detectFramework(_ content: String) -> DocumentFramework {
        let frameworkPatterns = [
            .swiftUI: ["SwiftUI", "@State", "@Binding", "View", "NavigationView"],
            .react: ["React", "useState", "useEffect", "jsx", "component"],
            .angular: ["Angular", "@Component", "@Injectable", "ngOnInit"],
            .vue: ["Vue", "v-if", "v-for", "@click", "computed"],
            .flutter: ["Flutter", "Widget", "StatefulWidget", "build"],
            .django: ["Django", "models.Model", "views.py", "urls.py"],
            .rails: ["Rails", "ActiveRecord", "controller", "routes.rb"]
        ]
        
        for (framework, patterns) in frameworkPatterns {
            let matches = patterns.filter { content.contains($0) }.count
            if matches >= 2 { return framework }
        }
        
        return .unknown
    }
    
    private func extractCompanyInfo(_ url: URL, _ content: String) -> String? {
        // Extract from URL domain
        if let host = url.host {
            let companyPatterns = [
                "developer.apple.com": "Apple",
                "docs.microsoft.com": "Microsoft",
                "developers.google.com": "Google",
                "developer.mozilla.org": "Mozilla",
                "docs.github.com": "GitHub",
                "docs.aws.amazon.com": "Amazon Web Services"
            ]
            
            for (domain, company) in companyPatterns {
                if host.contains(domain) { return company }
            }
        }
        
        // Extract from content patterns
        let contentPatterns = [
            "Apple Inc": "Apple",
            "Microsoft Corporation": "Microsoft",
            "Google LLC": "Google",
            "Meta Platforms": "Meta"
        ]
        
        for (pattern, company) in contentPatterns {
            if content.contains(pattern) { return company }
        }
        
        return nil
    }
}
```

### 2. Implement Table of Contents Extraction (Week 1-2)

#### Files to Modify
- `DocShop/Core/TOCExtractor.swift` (CREATE)
- `DocShop/Models/DocumentMetaData.swift` - Add TOC field

#### Implementation Details
```swift
struct TableOfContentsItem: Codable, Identifiable {
    let id = UUID()
    let title: String
    let level: Int
    let anchor: String
    let children: [TableOfContentsItem]
}

class TOCExtractor {
    static func extractTableOfContents(from html: String) throws -> [TableOfContentsItem] {
        let doc = try SwiftSoup.parse(html)
        let headings = try doc.select("h1, h2, h3, h4, h5, h6")
        
        var tocItems: [TableOfContentsItem] = []
        var stack: [(TableOfContentsItem, Int)] = []
        
        for heading in headings {
            let level = Int(heading.tagName().dropFirst()) ?? 1
            let title = try heading.text()
            let anchor = generateAnchor(from: title)
            
            let item = TableOfContentsItem(
                title: title,
                level: level,
                anchor: anchor,
                children: []
            )
            
            // Build hierarchical structure
            while !stack.isEmpty && stack.last!.1 >= level {
                stack.removeLast()
            }
            
            if stack.isEmpty {
                tocItems.append(item)
            } else {
                // Add as child to parent
                stack.last!.0.children.append(item)
            }
            
            stack.append((item, level))
        }
        
        return tocItems
    }
}
```

### 3. Implement Content Semantic Analysis (Week 2)

#### Files to Modify
- `DocShop/Core/SemanticAnalyzer.swift` (CREATE)
- `DocShop/Core/AIDocumentAnalyzer.swift` - Enhance analysis

#### Implementation Details
```swift
class SemanticAnalyzer {
    static let shared = SemanticAnalyzer()
    
    func analyzeContent(_ content: String) async -> ContentAnalysis {
        var analysis = ContentAnalysis()
        
        // Extract key concepts
        analysis.concepts = extractKeyConcepts(content)
        analysis.difficulty = assessDifficulty(content)
        analysis.contentType = classifyContentType(content)
        analysis.prerequisites = extractPrerequisites(content)
        analysis.relatedTopics = findRelatedTopics(content)
        
        return analysis
    }
    
    private func extractKeyConcepts(_ content: String) -> [String] {
        let technicalTerms = [
            "API", "SDK", "framework", "library", "protocol", "interface",
            "authentication", "authorization", "REST", "GraphQL", "WebSocket",
            "database", "cache", "queue", "microservice", "container"
        ]
        
        return technicalTerms.filter { content.localizedCaseInsensitiveContains($0) }
    }
    
    private func assessDifficulty(_ content: String) -> DifficultyLevel {
        let beginnerIndicators = ["tutorial", "getting started", "introduction", "basics"]
        let advancedIndicators = ["advanced", "optimization", "performance", "architecture"]
        
        let beginnerScore = beginnerIndicators.filter { content.localizedCaseInsensitiveContains($0) }.count
        let advancedScore = advancedIndicators.filter { content.localizedCaseInsensitiveContains($0) }.count
        
        if advancedScore > beginnerScore { return .advanced }
        if beginnerScore > 0 { return .beginner }
        return .intermediate
    }
}
```

### 4. Implement Document Relationship Detection (Week 2-3)

#### Files to Modify
- `DocShop/Core/RelationshipDetector.swift` (CREATE)
- `DocShop/Data/DocLibraryIndex.swift` - Add relationship tracking

#### Implementation Details
```swift
class RelationshipDetector {
    static let shared = RelationshipDetector()
    
    func findRelatedDocuments(for document: DocumentMetaData, in library: [DocumentMetaData]) -> [DocumentRelationship] {
        var relationships: [DocumentRelationship] = []
        
        for otherDoc in library where otherDoc.id != document.id {
            let similarity = calculateSimilarity(document, otherDoc)
            
            if similarity > 0.7 {
                relationships.append(DocumentRelationship(
                    targetDocument: otherDoc,
                    relationshipType: .similar,
                    strength: similarity
                ))
            }
            
            // Check for prerequisite relationships
            if isPrerequisite(otherDoc, for: document) {
                relationships.append(DocumentRelationship(
                    targetDocument: otherDoc,
                    relationshipType: .prerequisite,
                    strength: 0.9
                ))
            }
            
            // Check for follow-up relationships
            if isFollowUp(otherDoc, for: document) {
                relationships.append(DocumentRelationship(
                    targetDocument: otherDoc,
                    relationshipType: .followUp,
                    strength: 0.8
                ))
            }
        }
        
        return relationships.sorted { $0.strength > $1.strength }
    }
}
```

### 5. Implement Batch Document Processing (Week 3)

#### Files to Modify
- `DocShop/Core/BatchProcessor.swift` (CREATE)
- `DocShop/Views/DocumentDropView.swift` - Add batch import UI

#### Implementation Details
```swift
class BatchProcessor: ObservableObject {
    @Published var batchProgress: Double = 0.0
    @Published var currentBatchItem: String = ""
    @Published var batchResults: [BatchResult] = []
    
    func processBatch(_ urls: [String]) async {
        let total = urls.count
        
        for (index, url) in urls.enumerated() {
            await MainActor.run {
                currentBatchItem = url
                batchProgress = Double(index) / Double(total)
            }
            
            do {
                let document = try await DocumentProcessor.shared.importDocument(from: url)
                await MainActor.run {
                    batchResults.append(BatchResult(url: url, success: true, document: document))
                }
            } catch {
                await MainActor.run {
                    batchResults.append(BatchResult(url: url, success: false, error: error))
                }
            }
        }
        
        await MainActor.run {
            batchProgress = 1.0
        }
    }
}
```

### 6. Implement Content Validation & Quality Assessment (Week 3-4)

#### Files to Modify
- `DocShop/Core/ContentValidator.swift` (CREATE)
- `DocShop/Core/QualityAssessment.swift` (CREATE)

#### Implementation Details
```swift
class ContentValidator {
    static let shared = ContentValidator()
    
    func validateDocument(_ document: DocumentMetaData) async -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score: Double = 1.0
        
        // Check content completeness
        if document.summary?.count ?? 0 < 100 {
            issues.append(.incompleteSummary)
            score -= 0.2
        }
        
        // Check for broken links
        let brokenLinks = await findBrokenLinks(document)
        if !brokenLinks.isEmpty {
            issues.append(.brokenLinks(brokenLinks))
            score -= 0.1 * Double(brokenLinks.count)
        }
        
        // Check content freshness
        if let lastModified = document.dateModified,
           Date().timeIntervalSince(lastModified) > 365 * 24 * 60 * 60 { // 1 year
            issues.append(.outdatedContent)
            score -= 0.3
        }
        
        return ValidationResult(score: max(0, score), issues: issues)
    }
}
```

## Technical Context

### Existing Framework Assets
- **DocumentProcessor**: Solid foundation for basic processing
- **AppleDocsSpecialist**: Advanced Apple-specific processing
- **SmartDuplicateHandler**: Content comparison capabilities
- **AIDocumentAnalyzer**: AI integration framework

### Integration Points
- **Project System**: Enhanced metadata feeds into project creation
- **Search System**: Rich metadata enables advanced search
- **Knowledge Graph**: Relationships power graph visualization
- **AI Analysis**: Enhanced content feeds better AI decisions

### Success Criteria
1. **Rich Metadata**: All documents have comprehensive metadata
2. **Content Intelligence**: Automatic framework/language detection
3. **Relationship Detection**: Documents are linked by relevance
4. **Quality Assessment**: Content quality is measured and reported
5. **Batch Processing**: Multiple documents can be processed efficiently

### Code Quality Requirements
- Maintain existing async/await patterns
- Implement comprehensive error handling
- Add performance monitoring for large documents
- Create unit tests for all extractors
- Document all metadata fields and their sources

### Dependencies on Other Agents
- **Agent 1**: Project integration for document selection
- **Agent 3**: AI enhancement for semantic analysis
- **Agent 4**: Search integration for metadata utilization
- **Agent 5**: UI components for metadata display

## Deliverables

### Week 1
- [ ] Advanced metadata extraction system
- [ ] Table of contents extraction
- [ ] Framework/language detection

### Week 2
- [ ] Semantic content analysis
- [ ] Document relationship detection
- [ ] Content quality assessment

### Week 3
- [ ] Batch processing capabilities
- [ ] Content validation system
- [ ] Performance optimization

### Week 4
- [ ] Integration testing
- [ ] Metadata visualization
- [ ] Documentation and handoff

## Branch Strategy
- **Main branch**: `feature/document-processing-enhancement`
- **Sub-branches**:
  - `feature/metadata-extraction`
  - `feature/toc-extraction`
  - `feature/semantic-analysis`
  - `feature/relationship-detection`

## Testing Strategy
- Unit tests for all extractors and analyzers
- Integration tests with existing document processor
- Performance tests with large document sets
- Accuracy tests for metadata extraction