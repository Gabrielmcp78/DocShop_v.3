import SwiftUI

/// Enhanced project detail view with BMad integration and live execution
struct EnhancedProjectDetailView: View {
    let project: Project
    @StateObject private var executor = LiveTaskExecutor.shared
    @StateObject private var geminiAPI = EnhancedGeminiAPI.shared
    @State private var showingLiveExecution = false
    @State private var showingAPIKeySetup = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Project header with BMad status
                ProjectHeaderCard(project: project, geminiAPI: geminiAPI)
                
                // Quick actions
                QuickActionsCard(
                    project: project,
                    onStartExecution: { showingLiveExecution = true },
                    onConfigureAPI: { showingAPIKeySetup = true },
                    isAPIConnected: geminiAPI.isConnected
                )
                
                // BMad workflow status
                BMadWorkflowStatusCard(project: project, executor: executor)
                
                // Project tasks overview
                TasksOverviewCard(project: project)
                
                // Documents and requirements
                HStack(alignment: .top, spacing: 16) {
                    ProjectDocumentsCard(documents: project.documents)
                    ProjectRequirementsCard(requirements: project.requirements)
                }
                
                // Project metrics and health
                ProjectMetricsCard(project: project)
            }
            .padding()
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Configure AI") {
                    showingAPIKeySetup = true
                }
                .disabled(geminiAPI.isConnected)
                
                Button("Start BMad Execution") {
                    showingLiveExecution = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!geminiAPI.isConnected || executor.isExecuting)
            }
        }
        .sheet(isPresented: $showingLiveExecution) {
            NavigationView {
                LiveTaskExecutionView(project: project)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingLiveExecution = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingAPIKeySetup) {
            APIKeySetupView(isPresented: $showingAPIKeySetup)
        }
    }
}

// MARK: - Project Header Card

struct ProjectHeaderCard: View {
    let project: Project
    @ObservedObject var geminiAPI: EnhancedGeminiAPI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(project.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    ProjectStatusBadge(status: project.status)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(geminiAPI.isConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(geminiAPI.isConnected ? "AI Ready" : "AI Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Project metadata
            HStack(spacing: 20) {
                MetadataItem(title: "Created", value: project.createdAt.formatted(date: .abbreviated, time: .omitted))
                MetadataItem(title: "Tasks", value: "\(project.tasks.count)")
                MetadataItem(title: "Documents", value: "\(project.documents.count)")
                MetadataItem(title: "Agents", value: "\(project.agents.count)")
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProjectStatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .initialized: return .blue
        case .active: return .green
        case .paused: return .orange
        case .completed: return .purple
        case .error: return .red
        }
    }
}

struct MetadataItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Quick Actions Card

struct QuickActionsCard: View {
    let project: Project
    let onStartExecution: () -> Void
    let onConfigureAPI: () -> Void
    let isAPIConnected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActionButton(
                    title: "Start BMad Execution",
                    subtitle: "Begin AI-powered task execution",
                    icon: "play.circle.fill",
                    color: .blue,
                    isEnabled: isAPIConnected,
                    action: onStartExecution
                )
                
                ActionButton(
                    title: "Configure AI",
                    subtitle: "Set up Gemini API connection",
                    icon: "gear.circle.fill",
                    color: .orange,
                    isEnabled: !isAPIConnected,
                    action: onConfigureAPI
                )
                
                ActionButton(
                    title: "View Documentation",
                    subtitle: "Browse generated docs",
                    icon: "doc.text.fill",
                    color: .green,
                    isEnabled: true,
                    action: { /* TODO: Implement */ }
                )
                
                ActionButton(
                    title: "Export Results",
                    subtitle: "Download project artifacts",
                    icon: "square.and.arrow.up.fill",
                    color: .purple,
                    isEnabled: project.status == .completed,
                    action: { /* TODO: Implement */ }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isEnabled ? color : .gray)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? .primary : .gray)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 80)
            .background(isEnabled ? color.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - BMad Workflow Status Card

struct BMadWorkflowStatusCard: View {
    let project: Project
    @ObservedObject var executor: LiveTaskExecutor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BMad Workflow Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            if executor.isExecuting {
                // Live execution status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                            .symbolEffect(.pulse, isActive: true)
                        
                        Text("Execution in Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(executor.overallProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: executor.overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text(executor.currentPhase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Task summary
                    HStack(spacing: 16) {
                        StatusSummary(title: "Active", count: executor.activeTasks.count, color: .blue)
                        StatusSummary(title: "Completed", count: executor.completedTasks.count, color: .green)
                        StatusSummary(title: "Failed", count: executor.failedTasks.count, color: .red)
                        
                        Spacer()
                    }
                }
            } else {
                // Static workflow overview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet.circle")
                            .foregroundColor(.gray)
                        
                        Text("Ready for Execution")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    Text("BMad methodology workflow configured with \(project.tasks.count) tasks across multiple phases.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Phase breakdown
                    let phases = groupTasksByPhase(project.tasks)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(phases, id: \.0) { phase, tasks in
                            PhaseCard(name: phase, taskCount: tasks.count)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
    
    private func groupTasksByPhase(_ tasks: [ProjectTask]) -> [(String, [ProjectTask])] {
        let phases = [
            ("Analysis", tasks.filter { $0.context.info == "analysis" }),
            ("Design", tasks.filter { $0.context.info == "design" }),
            ("Implementation", tasks.filter { $0.context.info == "implementation" }),
            ("Documentation", tasks.filter { $0.context.info == "documentation" }),
            ("Testing", tasks.filter { $0.context.info == "testing" })
        ]
        
        return phases.filter { !$1.isEmpty }
    }
}

struct StatusSummary: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct PhaseCard: View {
    let name: String
    let taskCount: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(taskCount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

// MARK: - Tasks Overview Card

struct TasksOverviewCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            if project.tasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks Generated",
                    systemImage: "list.bullet",
                    description: Text("Tasks will be generated when BMad execution begins")
                )
                .frame(height: 120)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(project.tasks.prefix(5)) { task in
                        TaskPreviewRow(task: task)
                    }
                    
                    if project.tasks.count > 5 {
                        Text("... and \(project.tasks.count - 5) more tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

struct TaskPreviewRow: View {
    let task: ProjectTask
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.context.info.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(task.priority.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor.opacity(0.2))
                .foregroundColor(priorityColor)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending: return .orange
        case .assigned: return .blue
        case .inProgress: return .blue
        case .completed: return .green
        case .blocked: return .red
        case .error: return .red
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Supporting Cards

struct ProjectDocumentsCard: View {
    let documents: [DocumentMetaData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents (\(documents.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            if documents.isEmpty {
                Text("No documents attached")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(documents.prefix(3)) { doc in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text(doc.title)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                    
                    if documents.count > 3 {
                        Text("... and \(documents.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

struct ProjectRequirementsCard: View {
    let requirements: ProjectRequirements
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                RequirementRow(title: "Languages", items: requirements.targetLanguages.map { $0.rawValue })
                RequirementRow(title: "Features", items: requirements.sdkFeatures.map { $0.rawValue })
                RequirementRow(title: "Testing", items: requirements.testingRequirements.map { $0.rawValue })
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

struct RequirementRow: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(items.isEmpty ? "None" : items.joined(separator: ", "))
                .font(.caption)
                .lineLimit(2)
        }
    }
}

struct ProjectMetricsCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricItem(title: "Task Completion", value: taskCompletionRate, format: "%.0f%%")
                MetricItem(title: "Document Coverage", value: documentCoverage, format: "%.0f%%")
                MetricItem(title: "Quality Score", value: qualityScore, format: "%.1f/5.0")
                MetricItem(title: "Est. Duration", value: estimatedDuration, format: "%@")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
    
    private var taskCompletionRate: Double {
        guard !project.tasks.isEmpty else { return 0 }
        let completed = project.tasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(project.tasks.count) * 100
    }
    
    private var documentCoverage: Double {
        // Simulate document coverage calculation
        return min(Double(project.documents.count) * 20, 100)
    }
    
    private var qualityScore: Double {
        // Simulate quality score calculation
        return 4.2
    }
    
    private var estimatedDuration: String {
        // Simulate duration estimation
        return "2-3 hours"
    }
}

struct MetricItem: View {
    let title: String
    let value: Any
    let format: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let doubleValue = value as? Double {
                Text(String(format: format, doubleValue))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } else if let stringValue = value as? String {
                Text(String(format: format, stringValue))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        EnhancedProjectDetailView(
            project: Project(
                name: "Sample BMad Project",
                description: "A comprehensive test project showcasing BMad methodology integration",
                requirements: ProjectRequirements(
                    targetLanguages: [.swift, .python],
                    sdkFeatures: [.apiGeneration, .documentation],
                    documentationRequirements: [.readme, .apiReference],
                    testingRequirements: [.unit, .integration],
                    performanceBenchmarks: [.performance],
                    projectName: "Sample Project",
                    projectDescription: "Test description"
                ),
                documents: []
            )
        )
    }
}