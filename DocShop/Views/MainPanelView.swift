import SwiftUI

struct MainPanelView: View {
    let selectedItem: SidebarItem?
    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedItem {
        case .library:
            LibraryView()
        case .importItem:
            DocumentDropView()
        case .settings:
            EnhancedSettingsView()
        case .logs:
            LogViewerView()
        case .status:
            SystemStatusView()
        case .some(.projects):
            ProjectOrchestrationView()
        case .some(.aiSearch):
            Text("AI Search coming soon…")
        case .some(.knowledgeGraph):
            Text("Knowledge Graph coming soon…")
        case .some(.systemValidation):
            Text("System Validation coming soon…")
        case nil:
            Text("Select a tool to begin.")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassy()
    }
}
