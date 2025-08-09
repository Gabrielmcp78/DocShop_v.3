import SwiftUI

struct BMadDashboardView: View {
    @StateObject private var orchestrator = BMadOrchestrator()
    @State private var selectedWorkflowType: BMadWorkflowType = .greenfieldFullstack
    @State private var showingWorkflowCreation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                BMadHeaderView(orchestrator: orchestrator)
                
                // Current Workflow Status
                if let currentWorkflow = orchestrator.currentWorkflow {
                    BMadWorkflowStatusView(workflow: currentWorkflow, state: orchestrator.workflowState)
                } else {
                    BMadWelcomeView(onStartWorkflow: {
                        showingWorkflowCreation = true
                    })
                }
                
                // Active Agents
                if !orchestrator.activeAgents.isEmpty {
                    BMadActiveAgentsView(agents: orchestrator.activeAgents)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("BMad Integration")
            .sheet(isPresented: $showingWorkflowCreation) {
                BMadWorkflowCreationView(
                    selectedType: $selectedWorkflowType,
                    onCreateWorkflow: { workflowType, context in
                        Task {
                            await orchestrator.startWorkflow(workflowType, context: context)
                        }
                        showingWorkflowCreation = false
                    }
                )
            }
        }
    }
}

struct BMadHeaderView: View {
    @ObservedObject var orchestrator: BMadOrchestrator
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("BMad Methodology")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("AI-Powered Development Framework")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch orchestrator.workflowState {
        case .idle:
            return .gray
        case .planning:
            return .orange
        case .executing:
            return .blue
        case .reviewing:
            return .purple
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch orchestrator.workflowState {
        case .idle:
            return "Ready"
        case .planning:
            return "Planning"
        case .executing:
            return "Executing"
        case .reviewing:
            return "Reviewing"
        case .completed:
            return "Completed"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

struct BMadWelcomeView: View {
    let onStartWorkflow: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Welcome to BMad")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start an AI-powered development workflow to enhance DocShop with missing functionality.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Start New Workflow") {
                onStartWorkflow()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct BMadWorkflowStatusView: View {
    let workflow: BMadWorkflow
    let state: BMadOrchestrator.WorkflowState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(workflow.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(workflow.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: workflow.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            // Phases
            LazyVStack(spacing: 8) {
                ForEach(workflow.phases) { phase in
                    BMadPhaseRowView(phase: phase)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct BMadPhaseRowView: View {
    let phase: BMadWorkflowPhase
    
    var body: some View {
        HStack {
            Image(systemName: phase.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(phase.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !phase.isCompleted {
                ProgressView(value: phase.progress)
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BMadActiveAgentsView: View {
    let agents: [BMadAgent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Agents")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(agents) { agent in
                    BMadAgentCardView(agent: agent)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct BMadAgentCardView: View {
    let agent: BMadAgent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: agentIcon)
                    .foregroundColor(.blue)
                
                Text(agent.name.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if agent.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(agent.role.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Capabilities
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(agent.capabilities.prefix(3), id: \.self) { capability in
                        Text(capability)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var agentIcon: String {
        switch agent.role {
        case "orchestrator":
            return "person.3.sequence"
        case "analyst":
            return "chart.bar.doc.horizontal"
        case "architect":
            return "building.2"
        case "developer":
            return "hammer"
        case "tester":
            return "checkmark.seal"
        case "reviewer":
            return "eye"
        default:
            return "person.circle"
        }
    }
}

#Preview {
    BMadDashboardView()
}