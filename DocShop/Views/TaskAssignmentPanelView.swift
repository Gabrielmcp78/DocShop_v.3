import SwiftUI

struct TaskAssignmentPanelView: View {
    @ObservedObject var orchestrator = AgentOrchestrator.shared
    let tasks: [ProjectTask]
    let agents: [DevelopmentAgent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks")
                .font(.title2)
                .fontWeight(.semibold)
            if tasks.isEmpty {
                Text("No tasks defined.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(tasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.headline)
                            Text(task.status.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let agentID = task.assignedAgentID, let agent = orchestrator.agent(for: agentID) {
                                Text("Assigned to: \(agent.name)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                        Menu {
                            ForEach(agents, id: \ .id) { agent in
                                Button(agent.name) {
                                    orchestrator.assign(task: task, to: agent)
                                }
                            }
                        } label: {
                            Label("Assign", systemImage: "person.crop.circle.badge.plus")
                        }
                        Menu {
                            ForEach(ProjectTaskStatus.allCases, id: \ .self) { status in
                                Button(status.rawValue.capitalized) {
                                    orchestrator.updateStatus(for: task, to: status)
                                }
                            }
                        } label: {
                            Label("Update Status", systemImage: "checkmark.circle")
                        }
                    }
                    Divider()
                }
            }
        }
        .glassy()
        .padding(.vertical, 8)
    }
} 