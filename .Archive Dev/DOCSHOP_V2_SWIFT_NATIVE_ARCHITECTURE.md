# DocShop v2.0 - Swift-Native Architecture Proposal

## Executive Summary

This proposal restructures DocShop v2.0 to maximize Swift/macOS native technologies while maintaining the Neuroplastic Memory Core and zero-cost local development approach. The architecture prioritizes Swift frameworks, macOS system services, and native performance.

## Swift-Native Technology Stack

### Core Infrastructure (All Swift)
- **Vapor**: Swift backend framework (already planned)
- **SwiftData**: Primary data persistence layer
- **SwiftNIO**: High-performance networking
- **GRDB**: SQLite with Swift bindings (alternative to PostgreSQL)
- **Core Data**: Alternative for complex relational data
- **CloudKit**: Optional sync capabilities

### Search & Intelligence (Swift-Native)
- **Core ML**: Local machine learning and embeddings
- **Natural Language**: Text processing and NLP
- **Create ML**: Custom model training
- **Speech**: Voice interface capabilities
- **Core Spotlight**: System-wide search integration

### Networking & APIs (Swift-Native)
- **URLSession**: HTTP client
- **Multipeer Connectivity**: Local network discovery
- **Network.framework**: Low-level networking
- **Combine**: Reactive programming

## Revised Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                DocShop v2.0 - Swift Native Architecture         │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Layer (SwiftUI/AppKit)                                │
│  ├── SwiftUI App (macOS) - Primary Interface                   │
│  ├── Safari Extension (Swift/WebKit)                           │
│  ├── Spotlight Integration (Core Spotlight)                    │
│  └── Quick Look Plugin (Swift)                                 │
├─────────────────────────────────────────────────────────────────┤
│  Service Layer (Swift Services)                                 │
│  ├── Vapor API Server (Swift - Local)                          │
│  ├── XPC Services (Inter-process communication)                │
│  ├── Background Processing (Swift Concurrency)                 │
│  └── System Extensions (Document processing)                   │
├─────────────────────────────────────────────────────────────────┤
│  Intelligence Layer (Core ML/NLP)                               │
│  ├── Neuroplastic Memory Core (SwiftData + Core ML)            │
│  ├── Natural Language Processing (Foundation)                  │
│  ├── Local Embeddings (Core ML Models)                         │
│  ├── Document Analysis (Vision + NLP)                          │
│  └── Smart Recommendations (Create ML)                         │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer (Swift Data Frameworks)                             │
│  ├── SwiftData (Primary persistence - NMC)                     │
│  ├── GRDB/SQLite (Fast queries and FTS)                        │
│  ├── Core Data (Legacy/complex relationships)                  │
│  ├── FileManager (Document storage)                            │
│  └── CloudKit (Optional sync)                                  │
├─────────────────────────────────────────────────────────────────┤
│  System Integration (macOS Native)                              │
│  ├── Core Spotlight (System search)                            │
│  ├── Quick Look (Document preview)                             │
│  ├── Automator/Shortcuts (Workflow integration)                │
│  ├── AppleScript/JavaScript (Automation)                       │
│  └── Keychain Services (Secure storage)                        │
└─────────────────────────────────────────────────────────────────┘
```

## Swift-Native Implementation Benefits

### 1. Performance Advantages
- **Native Memory Management**: ARC vs garbage collection
- **Zero-copy Data**: Direct Swift struct/class access
- **SIMD Optimizations**: Native vector operations
- **Metal Performance**: GPU acceleration for ML

### 2. Integration Benefits
- **Spotlight Integration**: Documents searchable system-wide
- **Quick Look**: Rich document previews
- **Shortcuts/Automator**: User workflow automation
- **Handoff/Continuity**: Cross-device experiences

### 3. Development Benefits
- **Single Language**: All code in Swift
- **Type Safety**: Compile-time error detection
- **Modern Concurrency**: async/await throughout
- **Xcode Integration**: Native debugging and profiling

## Neuroplastic Memory Core - Swift Native Implementation

### SwiftData Schema
```swift
@Model
class Memory {
    @Attribute(.unique) var id: UUID
    var title: String
    var contentPreview: String
    var tags: [String]
    var strengthNumeric: Double
    var strengthLastAccessed: Date
    var strengthFrequency: Int
    var strengthAccessedBy: [String]
    var phase: MemoryPhase
    var createdAt: Date
    var projectID: String?
    var createdBy: String?
    var visibility: String
    var documentID: String?
    
    // Relationships
    @Relationship var associations: [MemoryAssociation]
    @Relationship var concepts: [Concept]
    
    init(title: String, content: String) {
        self.id = UUID()
        self.title = title
        self.contentPreview = content
        self.tags = []
        self.strengthNumeric = 1.0
        self.strengthLastAccessed = Date()
        self.strengthFrequency = 1
        self.strengthAccessedBy = []
        self.phase = .simple
        self.createdAt = Date()
    }
}

@Model
class MemoryAssociation {
    var sourceMemory: Memory
    var targetMemory: Memory
    var associationType: String
    var strength: Double
    var isManual: Bool
    var createdAt: Date
}

enum MemoryPhase: String, CaseIterable, Codable {
    case simple = "SIMPLE"
    case reinforced = "REINFORCED" 
    case consolidated = "CONSOLIDATED"
    case crystallized = "CRYSTALLIZED"
}
```

### Core ML Integration
```swift
import CoreML
import NaturalLanguage

class SwiftNativeEmbeddingService {
    private let embeddingModel: MLModel
    private let tokenizer: NLTokenizer
    
    func generateEmbedding(for text: String) async -> [Float] {
        // Use local Core ML model for embeddings
        // No external API calls required
    }
    
    func semanticSimilarity(_ text1: String, _ text2: String) async -> Double {
        // Local similarity computation
    }
}
```

## Revised Agent Responsibilities (Swift-Native)

### Agent 1: Swift Backend Infrastructure
**Tech Stack**: Vapor, SwiftNIO, GRDB, SwiftData
- Local Vapor server for API endpoints
- SwiftData models and persistence
- GRDB for full-text search
- XPC services for background processing

### Agent 2: Document Processing (Swift-Native)
**Tech Stack**: Foundation, Vision, NLP, WebKit
- Swift-based web crawling with URLSession
- WebKit for JavaScript rendering
- Vision framework for document analysis
- Natural Language for content extraction

### Agent 3: AI/ML Intelligence (Core ML)
**Tech Stack**: Core ML, Create ML, Natural Language
- Core ML models for local embeddings
- Create ML for custom model training
- Natural Language for semantic processing
- SwiftData for NMC persistence

### Agent 4: SwiftUI Frontend & System Integration
**Tech Stack**: SwiftUI, AppKit, Core Spotlight, Quick Look
- Advanced SwiftUI interfaces
- Core Spotlight integration
- Quick Look plugins
- System services integration

## Alternative Database Options

### Option 1: SwiftData + GRDB Hybrid
```swift
// SwiftData for NMC and relationships
@Model class Memory { }

// GRDB for full-text search and complex queries
class DocumentSearchService {
    private let dbQueue: DatabaseQueue
    
    func fullTextSearch(_ query: String) -> [SearchResult] {
        // SQLite FTS5 with Swift bindings
    }
}
```

### Option 2: Pure SwiftData with Custom Indexing
```swift
// Custom search implementation using SwiftData
class SwiftDataSearchService {
    @Query private var memories: [Memory]
    
    func semanticSearch(_ query: String) async -> [Memory] {
        // Custom in-memory search with Core ML
    }
}
```

### Option 3: Core Data + CloudKit
```swift
// For complex relationships and sync
class CoreDataNMCStack {
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        // CloudKit sync capabilities
    }()
}
```

## System Integration Advantages

### Spotlight Integration
```swift
import CoreSpotlight

class SpotlightIndexer {
    func indexDocument(_ document: Document) {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText)
        attributeSet.title = document.title
        attributeSet.contentDescription = document.summary
        
        let item = CSSearchableItem(
            uniqueIdentifier: document.id.uuidString,
            domainIdentifier: "com.docshop.documents",
            attributeSet: attributeSet
        )
        
        CSSearchableIndex.default().indexSearchableItems([item])
    }
}
```

### Quick Look Integration
```swift
import QuickLook

class DocumentPreviewProvider: QLPreviewProvider {
    override func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        // Custom document rendering
    }
}
```

### Shortcuts Integration
```swift
import AppIntents

struct SearchDocumentsIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Documents"
    
    @Parameter(title: "Query")
    var query: String
    
    func perform() async throws -> some ReturnsValue<[DocumentEntity]> {
        // Expose search to Shortcuts app
    }
}
```

## Performance Optimizations

### Swift Concurrency
```swift
actor MemoryManager {
    private var memories: [UUID: Memory] = [:]
    
    func addMemory(_ memory: Memory) async {
        memories[memory.id] = memory
    }
    
    func searchMemories(_ query: String) async -> [Memory] {
        // Thread-safe operations
    }
}
```

### Memory-Mapped File I/O
```swift
import Foundation

class MMapDocumentStore {
    func storeDocument(_ content: Data, at path: URL) throws {
        // Memory-mapped file operations for large documents
    }
}
```

## Migration Strategy

### Phase 1: Core Swift Infrastructure
- Replace Express.js with Vapor
- Migrate PostgreSQL to SwiftData + GRDB
- Implement SwiftNIO networking

### Phase 2: Native Intelligence
- Replace external embeddings with Core ML
- Implement Natural Language processing
- Local model training with Create ML

### Phase 3: System Integration
- Spotlight integration
- Quick Look plugins
- Shortcuts/Automator support

## Recommended Architecture Decision

**Preferred Stack:**
- **Backend**: Vapor + SwiftData + GRDB
- **Intelligence**: Core ML + Natural Language + Create ML
- **Frontend**: SwiftUI + System Frameworks
- **Storage**: SwiftData (NMC) + GRDB (Search) + FileManager (Documents)
- **Networking**: URLSession + SwiftNIO

This approach maximizes Swift ecosystem benefits while maintaining all planned functionality and cost-zero operation.

## Trade-offs Analysis

### Advantages of Swift-Native
✅ **Performance**: Native code, no VM overhead
✅ **Integration**: Deep macOS system integration
✅ **Maintenance**: Single language codebase
✅ **Security**: Sandboxing and entitlements
✅ **User Experience**: Native look and feel

### Potential Limitations
⚠️ **Scalability**: SQLite vs PostgreSQL for large datasets
⚠️ **Ecosystem**: Fewer third-party libraries
⚠️ **Web Interface**: Would need separate web stack for browser access
⚠️ **Cross-platform**: macOS-specific (though iOS/visionOS possible)

## Recommendation

**Go Swift-Native** for the primary implementation. The benefits far outweigh the limitations for a macOS-focused documentation system. You can always add web interfaces later using Vapor's capabilities, while maintaining the core intelligence and performance advantages of the native stack.

This architecture delivers the same powerful NMC functionality while staying true to the Swift/macOS ecosystem you prefer.