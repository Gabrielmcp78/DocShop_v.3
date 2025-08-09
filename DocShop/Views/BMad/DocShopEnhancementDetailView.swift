import SwiftUI

struct DocShopEnhancementDetailView: View {
    let enhancement: DocShopEnhancement
    let onStartImplementation: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    EnhancementHeaderView(enhancement: enhancement)
                    
                    // Description
                    EnhancementDescriptionView(enhancement: enhancement)
                    
                    // Technical Details
                    EnhancementTechnicalDetailsView(enhancement: enhancement)
                    
                    // Implementation Plan
                    EnhancementImplementationPlanView(enhancement: enhancement)
                    
                    // Dependencies
                    if !enhancement.dependencies.isEmpty {
                        EnhancementDependenciesView(dependencies: enhancement.dependencies)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(enhancement.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Start Implementation") {
                        onStartImplementation()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct EnhancementHeaderView: View {
    let enhancement: DocShopEnhancement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PriorityBadge(priority: enhancement.priority)
                EffortBadge(effort: enhancement.estimatedEffort)
                Spacer()
            }
            
            Text(enhancement.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct EnhancementDescriptionView: View {
    let enhancement: DocShopEnhancement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enhancement Overview")
                .font(.headline)
            
            Text(getDetailedDescription(for: enhancement))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func getDetailedDescription(for enhancement: DocShopEnhancement) -> String {
        switch enhancement.name {
        case "Advanced Search System":
            return """
            This enhancement will implement a comprehensive search system for DocShop that goes beyond basic text matching. The system will include:
            
            • Full-text search across all document content
            • Metadata-based filtering (date, type, size, etc.)
            • Tag-based search and filtering
            • Search result ranking and relevance scoring
            • Search history and saved searches
            • Advanced query syntax support
            • Real-time search suggestions
            
            The search system will be built using Core Data's full-text search capabilities combined with custom indexing for improved performance.
            """
            
        case "Document Export System":
            return """
            A robust document export system that allows users to export their documents in multiple formats while preserving formatting and metadata:
            
            • PDF export with customizable layouts
            • Microsoft Word (.docx) export
            • HTML export with embedded styles
            • Markdown export for technical documentation
            • Batch export capabilities
            • Export templates and customization options
            • Metadata preservation across formats
            • Progress tracking for large exports
            
            The system will use native macOS frameworks where possible and third-party libraries for specialized formats.
            """
            
        case "Document Tagging System":
            return """
            An intelligent tagging and categorization system to help users organize their document library:
            
            • Manual tag creation and assignment
            • Automatic tag suggestions based on content
            • Hierarchical tag structures
            • Tag-based filtering and search
            • Tag analytics and usage statistics
            • Bulk tagging operations
            • Tag import/export functionality
            • Smart collections based on tags
            
            The system will integrate with the existing Core Data model and provide a seamless user experience.
            """
            
        case "Enhanced Document Processing":
            return """
            Improvements to the core document processing pipeline to make it more robust and user-friendly:
            
            • Better error handling and recovery
            • Progress tracking for long operations
            • Parallel processing for multiple documents
            • Improved file format support
            • Processing queue management
            • Retry mechanisms for failed operations
            • Processing analytics and reporting
            • User notifications for processing events
            
            These enhancements will make DocShop more reliable and provide better feedback to users.
            """
            
        case "Document Version Control":
            return """
            A version control system for documents that tracks changes over time:
            
            • Automatic version creation on document updates
            • Version comparison and diff viewing
            • Version restoration capabilities
            • Version metadata and annotations
            • Storage optimization for versions
            • Version pruning and cleanup
            • Integration with document editing workflows
            • Version-based search and filtering
            
            This system will help users track document evolution and recover from unwanted changes.
            """
            
        default:
            return enhancement.description
        }
    }
}

struct EnhancementTechnicalDetailsView: View {
    let enhancement: DocShopEnhancement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technical Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Target Files", value: "\(enhancement.targetFiles.count) files")
                DetailRow(title: "Estimated Effort", value: enhancement.estimatedEffort.displayName)
                DetailRow(title: "Priority Level", value: enhancement.priority.rawValue.capitalized)
                DetailRow(title: "Dependencies", value: enhancement.dependencies.isEmpty ? "None" : "\(enhancement.dependencies.count) dependencies")
            }
            
            if !enhancement.targetFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files to be Modified:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(enhancement.targetFiles, id: \.self) { file in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(file)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct EnhancementImplementationPlanView: View {
    let enhancement: DocShopEnhancement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Implementation Plan")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getImplementationSteps(for: enhancement), id: \.self) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.blue)
                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func getImplementationSteps(for enhancement: DocShopEnhancement) -> [String] {
        switch enhancement.name {
        case "Advanced Search System":
            return [
                "Analyze current search requirements and limitations",
                "Design search architecture and data models",
                "Implement full-text search indexing",
                "Create search UI components",
                "Add filtering and sorting capabilities",
                "Implement search result ranking",
                "Add search history and saved searches",
                "Test search performance and accuracy"
            ]
            
        case "Document Export System":
            return [
                "Research export format requirements",
                "Design export architecture and interfaces",
                "Implement PDF export functionality",
                "Add Word document export support",
                "Create HTML and Markdown exporters",
                "Build export UI and progress tracking",
                "Add batch export capabilities",
                "Test export quality and performance"
            ]
            
        case "Document Tagging System":
            return [
                "Design tag data model and relationships",
                "Implement tag creation and management",
                "Create tagging UI components",
                "Add automatic tag suggestion logic",
                "Implement tag-based filtering",
                "Create tag analytics and reporting",
                "Add bulk tagging operations",
                "Test tag performance and usability"
            ]
            
        default:
            return [
                "Analyze current implementation",
                "Design enhancement architecture",
                "Implement core functionality",
                "Create user interface components",
                "Add error handling and validation",
                "Implement testing and quality assurance",
                "Optimize performance",
                "Deploy and monitor"
            ]
        }
    }
}

struct EnhancementDependenciesView: View {
    let dependencies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dependencies")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(dependencies, id: \.self) { dependency in
                    HStack {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.orange)
                        Text(dependency)
                            .font(.subheadline)
                    }
                }
            }
            
            Text("These enhancements must be completed before this one can be implemented.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

#Preview {
    DocShopEnhancementDetailView(
        enhancement: DocShopEnhancement(
            id: UUID(),
            name: "Advanced Search System",
            description: "Implement comprehensive search functionality",
            priority: .high,
            estimatedEffort: .medium,
            targetFiles: ["SearchEngine.swift", "SearchView.swift"],
            dependencies: []
        ),
        onStartImplementation: {}
    )
}