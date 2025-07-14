import SwiftUI

struct AgentPanelView: View {
    let agents: [DevelopmentAgent]
    @State private var showAssignTaskSheet = false
    @State private var selectedAgent: DevelopmentAgent?
    @State private var showMessageAlert = false
    @State private var showLogsAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agents")
                .font(.title2)
                .fontWeight(.semibold)
            if agents.isEmpty {
                Text("No agents assigned.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(agents, id: \ .id) { agent in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(agent.name)
                                .font(.headline)
                            Text(agent.specialization.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            selectedAgent = agent
                            showAssignTaskSheet = true
                        }) {
                            Label("Assign Task", systemImage: "plus.circle")
                        }
                        Button(action: {
                            selectedAgent = agent
                            showMessageAlert = true
                        }) {
                            Label("Message", systemImage: "bubble.left")
                        }
                        Button(action: {
                            selectedAgent = agent
                            showLogsAlert = true
                        }) {
                            Label("Logs", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                    Divider()
                }
            }
        }
        .padding(.vertical, 8)
        .glassy()
        .sheet(isPresented: $showAssignTaskSheet) {
            if let agent = selectedAgent {
                AssignTaskSheet(agent: agent)
            } else {
                Text("No agent selected.")
            }
        }
        .alert(isPresented: $showMessageAlert) {
            Alert(title: Text("Message Agent"), message: Text("Messaging \(selectedAgent?.name ?? "") (stub)"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showLogsAlert) {
            Alert(title: Text("Agent Logs"), message: Text("Viewing logs for \(selectedAgent?.name ?? "") (stub)"), dismissButton: .default(Text("OK")))
        }
    }
} 

// MARK: - Task Assignment Sheet
struct AssignTaskSheet: View {
    let agent: DevelopmentAgent
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTask: ProjectTask?
    @State private var availableTasks: [ProjectTask] = []
    @State private var assignStatus: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assign Task to \(agent.name)")
                .font(.headline)
            if availableTasks.isEmpty {
                Text("No available tasks.")
                    .foregroundColor(.secondary)
            } else {
                Picker("Task", selection: $selectedTask) {
                    ForEach(availableTasks, id: \.id) { task in
                        Text(task.title).tag(Optional(task))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Button("Assign Task") {
                    if let task = selectedTask {
                        // Call real assignment logic here
                        assignTask(task, to: agent)
                        assignStatus = "Task assigned!"
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(selectedTask == nil)
            }
            if let status = assignStatus {
                Text(status).foregroundColor(.green)
            }
        }
        .padding()
        .onAppear {
            // Load available tasks (stub: replace with real fetch)
            availableTasks = ProjectTask.sampleTasks
        }
    }
    
    private func assignTask(_ task: ProjectTask, to agent: DevelopmentAgent) {
        // TODO: Connect to real task assignment logic (TaskDistributor, etc.)
        // For now, just print
        print("Assigned task \(task.title) to agent \(agent.name)")
    }
}

// MARK: - Sample Data for Preview
extension ProjectTask {
    static var sampleTasks: [ProjectTask] {
        [
            ProjectTask(
                id: UUID(),
                title: "Implement API",
                description: "",
                status: .pending,
                priority: .medium,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "")
            ),
            ProjectTask(
                id: UUID(),
                title: "Write Docs",
                description: "",
                status: .pending,
                priority: .medium,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "")
            ),
            ProjectTask(
                id: UUID(),
                title: "Add Tests",
                description: "",
                status: .pending,
                priority: .medium,
                assignedAgentID: nil,
                benchmarks: [],
                context: TaskContext(info: "")
            )
        ]
    }
} 
