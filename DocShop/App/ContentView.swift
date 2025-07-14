import SwiftUI

struct ContentView: View {
    @State private var selectedSidebarItem: SidebarItem? = .library
    @ObservedObject private var processor = DocumentProcessor.shared
    @ObservedObject private var library = DocLibraryIndex.shared
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            EnhancedSidebarView(selection: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            Group {
                switch selectedSidebarItem {
                case .library:
                    AnyView(LibraryView())
                case .importItem:
                    AnyView(DocumentDropView())
                case .settings:
                    AnyView(EnhancedSettingsView())
                case .logs:
                    AnyView(LogViewerView())
                case .status:
                    AnyView(SystemStatusView())
                case .projects:
                    AnyView(ProjectOrchestrationView())
                case .aiSearch:
                    AnyView(AISearchView())
                case .none:
                    AnyView(EmptyStateView())
                case .some(.knowledgeGraph):
                    AnyView(Text("Knowledge Graph View")) // Replace with real view if available
                case .some(.systemValidation):
                    AnyView(Text("System Validation View"))
                }
            }
            .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if processor.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.2)
                        Text(processor.currentStatus)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    library.refreshLibrary()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(processor.isProcessing)
                .help("Refresh Library")
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            // Perform startup cleanup
            DocumentStorage.shared.cleanupOrphanedFiles()
        }
    }
}

enum SidebarItem: String, CaseIterable, Hashable {
    case library = "library"
    case importItem = "import"
    case settings = "settings"
    case logs = "logs"
    case status = "status"
    case projects = "projects"
    case aiSearch = "aiSearch"
    case knowledgeGraph = "knowledgeGraph"
    case systemValidation = "systemValidation"
    
    var displayName: String {
        switch self {
        case .library:
            return "Library"
        case .importItem:
            return "Import"
        case .settings:
            return "Settings"
        case .logs:
            return "Logs"
        case .status:
            return "System Status"
        case .projects:
            return "Projects"
        case .aiSearch:
            return "AI Search"
        case .knowledgeGraph:
            return "Knowledge Graph"
        case .systemValidation:
            return "System Validation"
        }
    }
    
    var iconName: String {
        switch self {
        case .library:
            return "books.vertical"
        case .importItem:
            return "square.and.arrow.down"
        case .settings:
            return "gear"
        case .logs:
            return "list.bullet.rectangle"
        case .status:
            return "info.circle"
        case .projects:
            return "folder.badge.gearshape"
        case .aiSearch:
            return "sparkles"
        case .knowledgeGraph:
            return "circle.grid.cross"
        case .systemValidation:
            return "checkmark.shield"
        }
    }
}

struct EnhancedSidebarView: View {
    @Binding var selection: SidebarItem?
    @ObservedObject private var library = DocLibraryIndex.shared
    @ObservedObject private var processor = DocumentProcessor.shared
    
    var body: some View {
        List(selection: $selection) {
            Section(header: Text("Documents")) {
                sidebarRow(for: .library)
                sidebarRow(for: .importItem)
            }
            Section(header: Text("AI & Search")) {
                sidebarRow(for: .aiSearch)
                sidebarRow(for: .knowledgeGraph)
            }
            Section(header: Text("Projects & Agents")) {
                sidebarRow(for: .projects)
            }
            Section(header: Text("System")) {
                sidebarRow(for: .status)
                sidebarRow(for: .systemValidation)
                sidebarRow(for: .logs)
                sidebarRow(for: .settings)
            }
        }
        .navigationTitle("DocShop")
        .listStyle(.sidebar)
        .onAppear {
            if selection == nil {
                selection = .library
            }
        }
    }
    
    @ViewBuilder
    private func sidebarRow(for item: SidebarItem) -> some View {
        NavigationLink(value: item) {
            HStack {
                Image(systemName: item.iconName)
                    .frame(width: 20)
                    .foregroundColor(selection == item ? .white : .primary)
                Text(item.displayName)
                    .foregroundColor(selection == item ? .white : .primary)
                Spacer()
                if item == .library {
                    Text("\(library.documents.count)")
                        .font(.caption)
                        .foregroundColor(selection == item ? .white.opacity(0.05) : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selection == item ? Color.clear.opacity(0.3) : Color.clear.opacity(0.07))
                        .cornerRadius(8)
                } else if item == .importItem && !processor.processingQueue.isEmpty {
                    Text("\(processor.processingQueue.count)")
                        .font(.caption)
                        .foregroundColor(selection == item ? .white.opacity(0.2) : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selection == item ? Color.white.opacity(0.07) : Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .tag(item)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 54))
                .foregroundColor(.secondary)
            
            Text("Welcome to DocShop")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Select an option from the sidebar to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
