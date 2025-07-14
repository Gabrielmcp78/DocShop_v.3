import SwiftUI

struct ProjectOrchestrationView: View {
    @ObservedObject private var orchestrator = AgentOrchestrator.shared
    @State private var selectedProject: Project?
    @State private var showingProjectCreation = false
    
    var body: some View {
        NavigationSplitView {
            ProjectListView(selectedProject: $selectedProject)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingProjectCreation = true }) {
                            Label("New Project", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else if showingProjectCreation {
                ProjectCreationView(isPresented: $showingProjectCreation)
            } else {
                Text("Select or create a project to begin.")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .glassy()
    }
}

#Preview {
    ProjectOrchestrationView()
} 