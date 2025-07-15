import SwiftUI

struct ContentView: View {
    @State private var selectedSidebarItem: SidebarItem? = .library
    @ObservedObject private var processor = DocumentProcessor.shared
    @ObservedObject private var library = DocLibraryIndex.shared

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(NavigationSplitViewVisibility.all),
            sidebar: {
                EnhancedSidebarView(selection: $selectedSidebarItem)
                    .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
            },
            detail: {
                selectedDetailView(for: selectedSidebarItem)
                    .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
            }
        )
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
            DocumentStorage.shared.cleanupOrphanedFiles()
        }
    }

    @ViewBuilder
    private func selectedDetailView(for item: SidebarItem?) -> some View {
        switch item {
        case .library:
            DocumentTableOfContentsView()
        case .importItem:
            DocumentDropView()
        case .settings:
            EnhancedSettingsView()
        case .logs:
            LogViewerView()
        case .status:
            SystemStatusView()
        case .projects:
            ProjectOrchestrationView()
        case .none:
            EmptyStateView()
        }
    }
}
