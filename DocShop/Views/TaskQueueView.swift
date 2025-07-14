import SwiftUI

struct TaskQueueView: View {
    let tasks: [ProjectTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if tasks.isEmpty {
                Text("No tasks defined.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(tasks) { task in
                    HStack {
                        Text(task.title)
                            .font(.headline)
                        Spacer()
                        Text(task.status.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(color(for: task.status))
                        Text(task.priority.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Divider()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func color(for status: ProjectTaskStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .assigned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .blocked: return .red
        case .error: return .pink
        }
    }
}

#Preview {
    TaskQueueView(tasks: [])
} 