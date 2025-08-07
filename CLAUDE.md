# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DocShop v3 is a macOS Swift application that provides intelligent documentation management with AI-powered analysis and multi-agent orchestration. The application ingests technical documentation, processes it through AI agents, and enables sophisticated search and project management capabilities.

## Build System & Development Commands

This is an Xcode-based macOS project using Swift Package Manager for dependencies:

```bash
# Build the project
xcodebuild -project DocShop.xcodeproj -scheme DocShop -configuration Debug build

# Run tests  
xcodebuild test -project DocShop.xcodeproj -scheme DocShop -destination 'platform=macOS'

# Clean build
xcodebuild -project DocShop.xcodeproj -scheme DocShop clean
```

**Key Dependencies:**
- SwiftSoup (HTML parsing)
- Hummingbird (HTTP server framework)  
- VisualEffects (UI effects)
- FoundationModels (AI/ML capabilities)

## Architecture Overview

### Core System Components

**Multi-Agent Architecture**: The system uses a sophisticated agent orchestration pattern with these key components:
- `AgentOrchestrator.swift` - Central coordination engine for all agents and projects
- `DevelopmentAgent.swift` - Base agent implementation for task execution
- `TaskDistributor.swift` - Intelligent task assignment based on agent capabilities
- `ContextManager.swift` - Maintains project context and agent alignment
- `ProgressTracker.swift` - Monitors progress and benchmarks across all activities

### Document Processing Pipeline

The document processing follows a multi-stage pipeline:
1. **DocumentImporter.swift** - Initial document ingestion and validation
2. **SmartDocumentProcessor.swift** - Intelligent content processing (DISABLED - was generating garbage)
3. **DocumentProcessor.swift** - Core document processing logic
4. **DocumentChunker.swift** - Breaks documents into processable chunks
5. **AIDocumentAnalyzer.swift** - AI-powered analysis and categorization
6. **DocumentSearchIndex.swift** - Maintains searchable index

### Data Models & Relationships

**Core Models** (in `DocShop/Models/`):
- `Project.swift` - Central project entity with document relationships, agent assignments, and task tracking
- `DocumentMetaData.swift` - Enhanced document metadata with categorization
- `IngestedDocument.swift` - Processed document representation
- `AgentTypes.swift` - Agent specializations, capabilities, and status tracking
- `AgentContextTypes.swift` - Context management for agent coordination

### API System

The application includes an embedded HTTP API server (via Hummingbird):
- `APIServer.swift` - Main API server setup and routing
- `DocumentAPI.swift` - Document-related endpoints
- `FilesystemAPI.swift` - File system operations
- `ShellAPI.swift` - Shell command execution

### Storage & Persistence

- `ProjectStorage.swift` - Project persistence layer
- `DocumentStorage.swift` - Document storage management  
- `Neo4jManager.swift` - Graph database integration for document relationships

## Key Development Patterns

### Agent System Usage

When working with agents, follow this pattern:
```swift
// Always use AgentOrchestrator as the central coordinator
let orchestrator = AgentOrchestrator.shared
let project = await orchestrator.createProject(from: documents, requirements: requirements)
await orchestrator.assignAgentsToProject(project)
```

### Document Processing

For document processing, use the pipeline approach:
```swift
let processor = SmartDocumentProcessor() // NOTE: Currently disabled
let chunks = DocumentChunker.shared.chunkDocument(document)
let analysis = await AIDocumentAnalyzer.shared.analyzeDocument(document)
```

### Context Management

Agent context should be managed through ContextManager:
```swift
let context = await contextManager.buildProjectContext(for: project)
await agent.updateContext(context)
```

## Testing Strategy

Tests are organized by domain in `DocShop/Models/Tests/`:
- `AgentContextTypesTests.swift` - Agent context validation
- `DocumentModelTests.swift` - Document model behavior  
- `ProjectRelationshipTests.swift` - Project relationship integrity

## Extensions & Integrations

The project includes several extension points:
- **DocShopIntent** - Siri Shortcuts integration for document import
- **DocShopShareExtension** - System share sheet integration
- **Multi-agent workspace** in `DocShop-v3-testing/` with individual agent environments

## Important Notes

- **SmartDocumentProcessor is currently DISABLED** - It was generating garbage output and should not be re-enabled without significant debugging
- The system uses `@MainActor` extensively - ensure UI updates happen on main actor
- Neo4j integration is present but may require local database setup
- The application requires macOS-specific entitlements (see `DocShop.entitlements`)
- Comprehensive documentation exists in `Documentation/` directory with analysis reports and implementation guides

## Multi-Agent Development

When working on agent functionality, refer to:
- Agent workspace READMEs in `DocShop-v3-testing/agent-workspaces/`
- Agent implementation docs in `Documentation/03-Multi-Agent-System/`
- Individual agent Swift files in respective workspace directories