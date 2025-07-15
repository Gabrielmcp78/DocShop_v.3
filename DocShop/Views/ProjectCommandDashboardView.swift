import SwiftUI

struct ProjectCommandDashboardView: View {
    @ObservedObject var orchestrator = AgentOrchestrator.shared
    let project: Project
    @State private var showAgents = false
    @State private var showTasks = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(project.description)
                        .font(.body)
                    HStack {
                        Text("Status: ")
                            .font(.headline)
                        Text(project.status.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { startProject() }) {
                        Label("Start", systemImage: "play.fill")
                    }
                    .disabled(project.status == .active)
                    
                    Button(action: { pauseProject() }) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .disabled(project.status != .active)
                    
                    Button(action: { showAgents.toggle() }) {
                        Label("Agents", systemImage: "person.3.fill")
                    }
                    Button(action: { showTasks.toggle() }) {
                        Label("Tasks", systemImage: "list.bullet.rectangle")
                    }
                }
            }
            Divider()
            if showAgents {
                AgentPanelView(agents: project.agents as! [DevelopmentAgent])
            }
            if showTasks {
                TaskAssignmentPanelView(
                    tasks: project.tasks,
                    agents: project.agents as! [DevelopmentAgent]
                )
            }
            Spacer()
        }
        .glassy()
        .padding()
    }
    
    private func startProject() {
        Task {
            await orchestrator.startProject(project)
        }
    }
    
    private func pauseProject() {
        Task {
            await orchestrator.pauseProject(project)
        }
    }
} 
