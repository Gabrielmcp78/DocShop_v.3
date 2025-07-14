import SwiftUI

struct AgentDashboardView: View {
    let agents: [DevelopmentAgent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if agents.isEmpty {
                Text("No agents assigned.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(agents, id: \ .id) { agent in
                    HStack {
                        Text(agent.name)
                            .font(.headline)
                        Text(agent.specialization.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(agent.status.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(color(for: agent.status))
                        if let task = agent.currentTask {
                            Text(task.title)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .glassy()
    }
    
    private func color(for status: AgentStatus) -> Color {
        switch status {
        case .idle: return .gray
        case .assigned: return .orange
        case .working: return .blue
        case .blocked: return .red
        case .completed: return .green
        case .error: return .red
        }
    }
}

#Preview {
    AgentDashboardView(agents: [])
} 