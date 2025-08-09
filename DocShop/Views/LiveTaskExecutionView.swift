import SwiftUI

/// Real-time task execution view with live progress tracking and animations
struct LiveTaskExecutionView: View {
    @StateObject private var executor = LiveTaskExecutor.shared
    @StateObject private var geminiAPI = EnhancedGeminiAPI.shared
    let project: Project
    
    @State private var showingDetails = false
    @State private var selectedTask: LiveTask?
    @State private var autoScroll = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with overall progress
            ExecutionHeaderView(
                project: project,
                executor: executor,
                onPause: { executor.pauseExecution() },
                onResume: { executor.resumeExecution() },
                onCancel: { executor.cancelExecution() }
            )
            
            // Main execution area
            HSplitView {
                // Left: Task list with live updates
                TaskListView(
                    activeTasks: executor.activeTasks,
                    completedTasks: executor.completedTasks,
                    failedTasks: executor.failedTasks,
                    selectedTask: $selectedTask,
                    autoScroll: $autoScroll
                )
                .frame(minWidth: 300, idealWidth: 400)
                
                // Right: Task details and logs
                TaskDetailView(
                    selectedTask: selectedTask,
                    geminiAPI: geminiAPI
                )
                .frame(minWidth: 400)
            }
            
            // Footer with phase progress
            PhaseProgressView(
                currentPhase: executor.currentPhase,
                overallProgress: executor.overallProgress
            )
        }
        .navigationTitle("Live BMad Execution")
        .onAppear {
            Task {
                await executor.startProjectExecution(project)
            }
        }
    }
}

// MARK: - Header Component

struct ExecutionHeaderView: View {
    let project: Project
    @ObservedObject var executor: LiveTaskExecutor
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Project info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("BMad Methodology Execution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Execution controls
                HStack(spacing: 8) {
                    if executor.isExecuting {
                        Button("Pause", action: onPause)
                            .buttonStyle(.bordered)
                    } else {
                        Button("Resume", action: onResume)
                            .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                }
            }
            
            // Overall progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(executor.overallProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: executor.overallProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .animation(.easeInOut(duration: 0.3), value: executor.overallProgress)
            }
            
            // Task summary
            HStack(spacing: 20) {
                TaskSummaryBadge(
                    title: "Active",
                    count: executor.activeTasks.count,
                    color: .blue,
                    isAnimated: true
                )
                
                TaskSummaryBadge(
                    title: "Completed",
                    count: executor.completedTasks.count,
                    color: .green,
                    isAnimated: false
                )
                
                TaskSummaryBadge(
                    title: "Failed",
                    count: executor.failedTasks.count,
                    color: .red,
                    isAnimated: false
                )
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
}

struct TaskSummaryBadge: View {
    let title: String
    let count: Int
    let color: Color
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .scaleEffect(isAnimated && count > 0 ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Task List Component

struct TaskListView: View {
    let activeTasks: [LiveTask]
    let completedTasks: [LiveTask]
    let failedTasks: [LiveTask]
    @Binding var selectedTask: LiveTask?
    @Binding var autoScroll: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Active tasks
                        if !activeTasks.isEmpty {
                            TaskSectionHeader(title: "Running", count: activeTasks.count, color: .blue)
                            
                            ForEach(activeTasks) { task in
                                LiveTaskRow(
                                    task: task,
                                    isSelected: selectedTask?.id == task.id,
                                    onSelect: { selectedTask = task }
                                )
                                .id(task.id)
                            }
                        }
                        
                        // Completed tasks
                        if !completedTasks.isEmpty {
                            TaskSectionHeader(title: "Completed", count: completedTasks.count, color: .green)
                            
                            ForEach(completedTasks) { task in
                                LiveTaskRow(
                                    task: task,
                                    isSelected: selectedTask?.id == task.id,
                                    onSelect: { selectedTask = task }
                                )
                            }
                        }
                        
                        // Failed tasks
                        if !failedTasks.isEmpty {
                            TaskSectionHeader(title: "Failed", count: failedTasks.count, color: .red)
                            
                            ForEach(failedTasks) { task in
                                LiveTaskRow(
                                    task: task,
                                    isSelected: selectedTask?.id == task.id,
                                    onSelect: { selectedTask = task }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: activeTasks.count) { _ in
                    if autoScroll, let lastTask = activeTasks.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastTask.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

struct TaskSectionHeader: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct LiveTaskRow: View {
    let task: LiveTask
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Status indicator
                    TaskStatusIndicator(status: task.status)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                        
                        Text(task.type.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Duration or progress
                    VStack(alignment: .trailing, spacing: 2) {
                        if task.status == .running {
                            Text("\(Int(task.progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        } else if let duration = task.duration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Progress bar for running tasks
                if task.status == .running {
                    ProgressView(value: task.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .animation(.easeInOut(duration: 0.3), value: task.progress)
                }
                
                // Latest log entry
                if let latestLog = task.logs.last {
                    Text(latestLog.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TaskStatusIndicator: View {
    let status: TaskStatus
    
    var body: some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            case .running:
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse, isActive: true)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "stop.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .font(.system(size: 16))
    }
}

// MARK: - Task Detail Component

struct TaskDetailView: View {
    let selectedTask: LiveTask?
    @ObservedObject var geminiAPI: EnhancedGeminiAPI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let task = selectedTask {
                // Task header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(task.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        TaskStatusIndicator(status: task.status)
                    }
                    
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Task metadata
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(task.type.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(task.startTime, style: .time)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        if let duration = task.duration {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDuration(duration))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Logs section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execution Log")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(task.logs.enumerated()), id: \.offset) { index, log in
                                LogEntryView(log: log, isLatest: index == task.logs.count - 1)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Result section
                if let result = task.result {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Result")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView {
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Error section
                if let error = task.error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                
            } else {
                // No task selected
                ContentUnavailableView(
                    "Select a Task",
                    systemImage: "list.bullet",
                    description: Text("Choose a task from the list to view its details and execution log")
                )
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct LogEntryView: View {
    let log: TaskLog
    let isLatest: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(log.message)
                .font(.caption)
                .foregroundColor(isLatest ? .primary : .secondary)
                .fontWeight(isLatest ? .medium : .regular)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .background(isLatest ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .animation(.easeInOut(duration: 0.3), value: isLatest)
    }
}

// MARK: - Phase Progress Component

struct PhaseProgressView: View {
    let currentPhase: String
    let overallProgress: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Phase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(currentPhase)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .animation(.easeInOut(duration: 0.3), value: currentPhase)
            }
            
            Spacer()
            
            // AI Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .symbolEffect(.pulse, isActive: true)
                
                Text("AI Connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

#Preview {
    let sampleProject = Project(
        name: "Sample BMad Project",
        description: "A test project for BMad methodology",
        requirements: ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.apiGeneration],
            documentationRequirements: [.readme],
            testingRequirements: [.unit],
            performanceBenchmarks: [.performance],
            projectName: "Sample Project",
            projectDescription: "Test description"
        ),
        documents: []
    )
    
    LiveTaskExecutionView(project: sampleProject)
}