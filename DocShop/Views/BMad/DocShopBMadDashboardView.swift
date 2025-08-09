import SwiftUI

struct DocShopBMadDashboardView: View {
    @StateObject private var integration = DocShopBMadIntegration()
    @State private var selectedEnhancement: DocShopEnhancement?
    @State private var showingEnhancementDetail = false
    @State private var analysis: DocShopAnalysis?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with DocShop Analysis
                DocShopAnalysisCard(analysis: analysis)
                
                // BMad Integration Status
                BMadIntegrationStatusCard(integration: integration)
                
                // Available Enhancements
                DocShopEnhancementsCard(
                    enhancements: integration.availableEnhancements,
                    onSelectEnhancement: { enhancement in
                        selectedEnhancement = enhancement
                        showingEnhancementDetail = true
                    },
                    onStartEnhancement: { enhancement in
                        Task {
                            await integration.startSpecificEnhancement(enhancement)
                        }
                    }
                )
                
                // Quick Actions
                DocShopQuickActionsCard(integration: integration)
            }
            .padding()
        }
        .navigationTitle("DocShop BMad Integration")
        .onAppear {
            analysis = integration.analyzeCurrentDocShopState()
        }
        .sheet(isPresented: $showingEnhancementDetail) {
            if let enhancement = selectedEnhancement {
                DocShopEnhancementDetailView(enhancement: enhancement) {
                    Task {
                        await integration.startSpecificEnhancement(enhancement)
                    }
                    showingEnhancementDetail = false
                }
            }
        }
    }
}

struct DocShopAnalysisCard: View {
    let analysis: DocShopAnalysis?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.blue)
                Text("DocShop Analysis")
                    .font(.headline)
                Spacer()
            }
            
            if let analysis = analysis {
                // Completeness Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Functionality Completeness")
                            .font(.subheadline)
                        Spacer()
                        Text("\(analysis.completenessPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: analysis.functionalityCompleteness)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: analysis.functionalityCompleteness)))
                }
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCard(title: "Documents", value: "\(analysis.totalDocuments)", icon: "doc.text")
                    StatCard(title: "Processing", value: "\(analysis.processingQueueSize)", icon: "gearshape.2")
                    StatCard(title: "Missing Features", value: "\(analysis.missingFeatures.count)", icon: "exclamationmark.triangle")
                }
                
                // Feature Status
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Implemented")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(analysis.implementedFeatures.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Missing")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(analysis.missingFeatures.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            } else {
                ProgressView("Analyzing DocShop...")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func progressColor(for value: Double) -> Color {
        if value < 0.3 { return .red }
        if value < 0.6 { return .orange }
        if value < 0.8 { return .yellow }
        return .green
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct BMadIntegrationStatusCard: View {
    @ObservedObject var integration: DocShopBMadIntegration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("BMad Integration Status")
                    .font(.headline)
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
            
            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch integration.integrationStatus {
        case .idle: return .gray
        case .analyzing: return .blue
        case .planning: return .orange
        case .implementing: return .purple
        case .testing: return .yellow
        case .completed: return .green
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch integration.integrationStatus {
        case .idle: return "Ready"
        case .analyzing: return "Analyzing"
        case .planning: return "Planning"
        case .implementing: return "Implementing"
        case .testing: return "Testing"
        case .completed: return "Completed"
        case .error: return "Error"
        }
    }
    
    private var statusDescription: String {
        switch integration.integrationStatus {
        case .idle:
            return "BMad integration is ready to enhance DocShop functionality"
        case .analyzing:
            return "Analyzing current DocShop architecture and identifying improvement opportunities"
        case .planning:
            return "Planning enhancement implementation strategy"
        case .implementing:
            return "Implementing selected enhancements"
        case .testing:
            return "Testing implemented enhancements"
        case .completed:
            return "Enhancement implementation completed successfully"
        case .error(let message):
            return "Error occurred: \(message)"
        }
    }
}

struct DocShopEnhancementsCard: View {
    let enhancements: [DocShopEnhancement]
    let onSelectEnhancement: (DocShopEnhancement) -> Void
    let onStartEnhancement: (DocShopEnhancement) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.green)
                Text("Available Enhancements")
                    .font(.headline)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(enhancements.prefix(5)) { enhancement in
                    DocShopEnhancementRow(
                        enhancement: enhancement,
                        onSelect: { onSelectEnhancement(enhancement) },
                        onStart: { onStartEnhancement(enhancement) }
                    )
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct DocShopEnhancementRow: View {
    let enhancement: DocShopEnhancement
    let onSelect: () -> Void
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(enhancement.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(enhancement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                PriorityBadge(priority: enhancement.priority)
                EffortBadge(effort: enhancement.estimatedEffort)
            }
            
            VStack(spacing: 4) {
                Button("Details") {
                    onSelect()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Start") {
                    onStart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PriorityBadge: View {
    let priority: DocShopEnhancement.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct EffortBadge: View {
    let effort: DocShopEnhancement.Effort
    
    var body: some View {
        Text(effort.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .cornerRadius(4)
    }
}

struct DocShopQuickActionsCard: View {
    @ObservedObject var integration: DocShopBMadIntegration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.circle")
                    .foregroundColor(.yellow)
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Full Enhancement",
                    description: "Start comprehensive DocShop enhancement",
                    icon: "wand.and.stars",
                    color: .blue
                ) {
                    Task {
                        await integration.startDocShopEnhancement()
                    }
                }
                
                QuickActionButton(
                    title: "Priority Features",
                    description: "Implement high-priority features first",
                    icon: "star.circle",
                    color: .orange
                ) {
                    // Start with high-priority enhancements
                    let highPriorityEnhancements = integration.availableEnhancements.filter { $0.priority == .high }
                    if let firstEnhancement = highPriorityEnhancements.first {
                        Task {
                            await integration.startSpecificEnhancement(firstEnhancement)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DocShopBMadDashboardView()
}