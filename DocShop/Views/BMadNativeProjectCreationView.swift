import SwiftUI

/// BMad-native project creation that treats methodology as the foundation, not an add-on
struct BMadNativeProjectCreationView: View {
    @Binding var isPresented: Bool
    @StateObject private var bmadOrchestrator = BMadOrchestrator()
    @StateObject private var docLibrary = DocLibraryIndex.shared
    
    // BMad-first approach: Start with methodology, not technical details
    @State private var projectVision: String = ""
    @State private var projectContext: String = ""
    @State private var selectedDocuments: Set<DocumentMetaData> = []
    @State private var bmadWorkflowType: BMadWorkflowType = .greenfieldFullstack
    @State private var projectConstraints: [String] = []
    @State private var newConstraint: String = ""
    
    // BMad methodology phases
    @State private var currentPhase: BMadCreationPhase = .vision
    @State private var isCreatingProject = false
    @State private var creationProgress: Double = 0.0
    
    enum BMadCreationPhase: String, CaseIterable {
        case vision = "Project Vision"
        case context = "Context Analysis" 
        case documentation = "Documentation Selection"
        case methodology = "BMad Workflow"
        case constraints = "Constraints & Requirements"
        case review = "Review & Create"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // BMad methodology progress indicator
                BMadPhaseProgressView(currentPhase: currentPhase, allPhases: BMadCreationPhase.allCases)
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentPhase {
                        case .vision:
                            ProjectVisionPhase(vision: $projectVision)
                        case .context:
                            ProjectContextPhase(context: $projectContext)
                        case .documentation:
                            DocumentationSelectionPhase(
                                selectedDocuments: $selectedDocuments,
                                availableDocuments: docLibrary.documents
                            )
                        case .methodology:
                            BMadWorkflowSelectionPhase(
                                selectedWorkflow: $bmadWorkflowType,
                                projectVision: projectVision,
                                selectedDocuments: Array(selectedDocuments)
                            )
                        case .constraints:
                            ConstraintsDefinitionPhase(
                                constraints: $projectConstraints,
                                newConstraint: $newConstraint
                            )
                        case .review:
                            ProjectReviewPhase(
                                vision: projectVision,
                                context: projectContext,
                                documents: Array(selectedDocuments),
                                workflow: bmadWorkflowType,
                                constraints: projectConstraints
                            )
                        }
                    }
                    .padding()
                }
                
                // BMad-style navigation
                BMadNavigationControls(
                    currentPhase: $currentPhase,
                    canProceed: canProceedToNextPhase(),
                    isCreating: isCreatingProject,
                    onCreateProject: createBMadProject,
                    onCancel: { isPresented = false }
                )
            }
        }
        .navigationTitle("Create BMad Project")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func canProceedToNextPhase() -> Bool {
        switch currentPhase {
        case .vision:
            return !projectVision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .context:
            return !projectContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .documentation:
            return !selectedDocuments.isEmpty
        case .methodology:
            return true // BMad workflow is always selected
        case .constraints:
            return true // Constraints are optional
        case .review:
            return true
        }
    }
    
    private func createBMadProject() {
        Task {
            isCreatingProject = true
            creationProgress = 0.0
            
            // Create BMad context from user inputs
            let bmadContext = BMadContext(
                projectPath: FileManager.default.currentDirectoryPath,
                targetFiles: selectedDocuments.map { $0.filePath },
                requirements: [projectVision, projectContext],
                constraints: projectConstraints,
                metadata: [
                    "vision": projectVision,
                    "context": projectContext,
                    "workflowType": bmadWorkflowType.rawValue,
                    "documentCount": "\(selectedDocuments.count)"
                ]
            )
            
            await updateProgress(0.2, "Initializing BMad workflow...")
            
            // Start BMad workflow - this IS the project creation, not a separate step
            await bmadOrchestrator.startWorkflow(bmadWorkflowType, context: bmadContext)
            
            await updateProgress(0.5, "Creating project structure...")
            
            // Create project with BMad methodology baked in
            let project = await createBMadNativeProject(context: bmadContext)
            
            await updateProgress(0.8, "Assigning BMad agents...")
            
            // The project IS a BMad workflow execution
            await initializeBMadExecution(for: project)
            
            await updateProgress(1.0, "Project created successfully!")
            
            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            isPresented = false
            isCreatingProject = false
        }
    }
    
    private func createBMadNativeProject(context: BMadContext) async -> Project {
        // Extract project name from vision (first sentence or first 50 chars)
        let projectName = extractProjectName(from: projectVision)
        
        // Create BMad-native project requirements
        let bmadRequirements = ProjectRequirements(
            targetLanguages: inferLanguagesFromDocuments(),
            sdkFeatures: inferFeaturesFromWorkflow(),
            documentationRequirements: inferDocumentationNeeds(),
            testingRequirements: inferTestingNeeds(),
            performanceBenchmarks: inferBenchmarks(),
            projectName: projectName,
            projectDescription: projectContext
        )
        
        // Create project through BMad orchestrator (not legacy AgentOrchestrator)
        let project = await bmadOrchestrator.createProject(
            vision: projectVision,
            context: context,
            requirements: bmadRequirements,
            documents: Array(selectedDocuments)
        )
        
        // Save to project storage
        await MainActor.run {
            ProjectStorage.shared.saveProject(project)
        }
        
        return project
    }
    
    private func initializeBMadExecution(for project: Project) async {
        // The project creation IS the BMad workflow initialization
        // No separate "start workflow" step needed
        await bmadOrchestrator.initializeProjectExecution(project)
    }
    
    private func updateProgress(_ progress: Double, _ message: String) async {
        await MainActor.run {
            self.creationProgress = progress
            // Could add status message display here
        }
    }
    
    // MARK: - BMad Intelligence: Infer requirements from methodology
    
    private func extractProjectName(from vision: String) -> String {
        let words = vision.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count >= 3 {
            return words.prefix(3).joined(separator: " ")
        } else {
            return words.joined(separator: " ")
        }
    }
    
    private func inferLanguagesFromDocuments() -> [ProgrammingLanguage] {
        let documentTypes = selectedDocuments.compactMap { doc in
            URL(string: doc.filePath)?.pathExtension.lowercased()
        }
        
        var languages: Set<ProgrammingLanguage> = []
        
        for ext in documentTypes {
            switch ext {
            case "swift": languages.insert(.swift)
            case "py": languages.insert(.python)
            case "js", "ts": languages.insert(.javascript)
            case "java": languages.insert(.java)
            case "cpp", "cc", "cxx": languages.insert(.cpp)
            case "rs": languages.insert(.rust)
            default: break
            }
        }
        
        // Default to Swift for DocShop context
        if languages.isEmpty {
            languages.insert(.swift)
        }
        
        return Array(languages)
    }
    
    private func inferFeaturesFromWorkflow() -> [SDKFeature] {
        switch bmadWorkflowType {
        case .greenfieldFullstack:
            return [.authentication, .asyncSupport, .customEndpoints, .codeExamples]
        case .featureEnhancement:
            return [.customEndpoints, .codeExamples, .logging]
        case .bugFix:
            return [.errorHandling, .logging]
        case .codeRefactor:
            return [.errorHandling, .logging, .asyncSupport]
        case .documentationUpdate:
            return [.codeExamples]
        }
    }
    
    private func inferDocumentationNeeds() -> [DocumentationType] {
        var needs: Set<DocumentationType> = [.apiReference, .gettingStarted]
        
        if selectedDocuments.count > 5 {
            needs.insert(.tutorials)
        }
        
        if bmadWorkflowType == .greenfieldFullstack {
            needs.insert(.architecture)
        }
        
        return Array(needs)
    }
    
    private func inferTestingNeeds() -> [TestingType] {
        switch bmadWorkflowType {
        case .greenfieldFullstack:
            return [.unit, .integration, .e2e]
        case .featureEnhancement:
            return [.unit, .integration]
        case .bugFix:
            return [.unit]
        case .codeRefactor:
            return [.unit, .integration, .performance]
        case .documentationUpdate:
            return [.unit]
        }
    }
    
    private func inferBenchmarks() -> [BenchmarkCriteria] {
        switch bmadWorkflowType {
        case .greenfieldFullstack:
            return [.performance, .reliability, .maintainability]
        case .featureEnhancement:
            return [.performance, .usability]
        case .bugFix:
            return [.reliability]
        case .codeRefactor:
            return [.performance, .maintainability]
        case .documentationUpdate:
            return [.usability]
        }
    }
}

// MARK: - BMad Phase Views

struct ProjectVisionPhase: View {
    @Binding var vision: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Vision")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Describe what you want to achieve with this project. BMad methodology starts with clear vision.")
                .foregroundColor(.secondary)
            
            TextEditor(text: $vision)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            if vision.isEmpty {
                Text("Example: Create a comprehensive SDK for Apple's documentation APIs with automated testing and deployment")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

struct ProjectContextPhase: View {
    @Binding var context: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Context Analysis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Provide context about the current situation, existing codebase, and specific challenges.")
                .foregroundColor(.secondary)
            
            TextEditor(text: $context)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

struct DocumentationSelectionPhase: View {
    @Binding var selectedDocuments: Set<DocumentMetaData>
    let availableDocuments: [DocumentMetaData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documentation Selection")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select the documentation that will inform the BMad agents about your project context.")
                .foregroundColor(.secondary)
            
            if availableDocuments.isEmpty {
                ContentUnavailableView(
                    "No Documentation Available",
                    systemImage: "doc.text",
                    description: Text("Import some documentation first to proceed with BMad project creation.")
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(availableDocuments) { doc in
                        DocumentSelectionRow(
                            document: doc,
                            isSelected: selectedDocuments.contains(doc),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedDocuments.insert(doc)
                                } else {
                                    selectedDocuments.remove(doc)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

struct BMadWorkflowSelectionPhase: View {
    @Binding var selectedWorkflow: BMadWorkflowType
    let projectVision: String
    let selectedDocuments: [DocumentMetaData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BMad Workflow Selection")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose the BMad workflow that best matches your project vision and context.")
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 12) {
                ForEach(BMadWorkflowType.allCases, id: \.self) { workflow in
                    BMadWorkflowCard(
                        workflow: workflow,
                        isSelected: selectedWorkflow == workflow,
                        recommendationScore: calculateRecommendationScore(for: workflow),
                        onSelect: { selectedWorkflow = workflow }
                    )
                }
            }
        }
    }
    
    private func calculateRecommendationScore(for workflow: BMadWorkflowType) -> Double {
        var score = 0.0
        
        // Analyze vision text for workflow hints
        let visionLower = projectVision.lowercased()
        
        switch workflow {
        case .greenfieldFullstack:
            if visionLower.contains("create") || visionLower.contains("new") || visionLower.contains("build") {
                score += 0.4
            }
            if selectedDocuments.count > 3 {
                score += 0.3
            }
        case .featureEnhancement:
            if visionLower.contains("add") || visionLower.contains("enhance") || visionLower.contains("improve") {
                score += 0.5
            }
        case .bugFix:
            if visionLower.contains("fix") || visionLower.contains("bug") || visionLower.contains("issue") {
                score += 0.6
            }
        case .codeRefactor:
            if visionLower.contains("refactor") || visionLower.contains("restructure") || visionLower.contains("optimize") {
                score += 0.5
            }
        case .documentationUpdate:
            if visionLower.contains("document") || visionLower.contains("guide") || visionLower.contains("readme") {
                score += 0.4
            }
        }
        
        return min(score, 1.0)
    }
}

struct ConstraintsDefinitionPhase: View {
    @Binding var constraints: [String]
    @Binding var newConstraint: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Constraints & Requirements")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Define any specific constraints or requirements that BMad agents should consider.")
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Add constraint...", text: $newConstraint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    if !newConstraint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        constraints.append(newConstraint.trimmingCharacters(in: .whitespacesAndNewlines))
                        newConstraint = ""
                    }
                }
                .disabled(newConstraint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if !constraints.isEmpty {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(constraints.enumerated()), id: \.offset) { index, constraint in
                        HStack {
                            Text("• \(constraint)")
                            Spacer()
                            Button("Remove") {
                                constraints.remove(at: index)
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct ProjectReviewPhase: View {
    let vision: String
    let context: String
    let documents: [DocumentMetaData]
    let workflow: BMadWorkflowType
    let constraints: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Project Review")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                ReviewSection(title: "Vision", content: vision)
                ReviewSection(title: "Context", content: context)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Documents")
                        .font(.headline)
                    Text("\(documents.count) documents selected")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("BMad Workflow")
                        .font(.headline)
                    Text(workflow.displayName)
                        .foregroundColor(.secondary)
                }
                
                if !constraints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Constraints")
                            .font(.headline)
                        ForEach(constraints, id: \.self) { constraint in
                            Text("• \(constraint)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BMadPhaseProgressView: View {
    let currentPhase: BMadNativeProjectCreationView.BMadCreationPhase
    let allPhases: [BMadNativeProjectCreationView.BMadCreationPhase]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(allPhases.enumerated()), id: \.offset) { index, phase in
                let isCompleted = allPhases.firstIndex(of: currentPhase)! > index
                let isCurrent = phase == currentPhase
                
                Circle()
                    .fill(isCompleted ? Color.green : (isCurrent ? Color.blue : Color.gray))
                    .frame(width: 12, height: 12)
                
                if index < allPhases.count - 1 {
                    Rectangle()
                        .fill(isCompleted ? Color.green : Color.gray)
                        .frame(height: 2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct BMadWorkflowCard: View {
    let workflow: BMadWorkflowType
    let isSelected: Bool
    let recommendationScore: Double
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(workflow.displayName)
                            .font(.headline)
                        
                        if recommendationScore > 0.5 {
                            Text("RECOMMENDED")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(workflow.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DocumentSelectionRow: View {
    let document: DocumentMetaData
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: { onToggle(!isSelected) }) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .blue : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.title)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        
                        Text(document.summary ?? "No summary available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct BMadNavigationControls: View {
    @Binding var currentPhase: BMadNativeProjectCreationView.BMadCreationPhase
    let canProceed: Bool
    let isCreating: Bool
    let onCreateProject: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Button("Cancel", action: onCancel)
            
            Spacer()
            
            if currentPhase != .vision {
                Button("Previous") {
                    moveToPreviousPhase()
                }
            }
            
            if currentPhase == .review {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Create Project", action: onCreateProject)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Button("Next") {
                    moveToNextPhase()
                }
                .disabled(!canProceed)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private func moveToNextPhase() {
        let phases = BMadNativeProjectCreationView.BMadCreationPhase.allCases
        if let currentIndex = phases.firstIndex(of: currentPhase),
           currentIndex < phases.count - 1 {
            currentPhase = phases[currentIndex + 1]
        }
    }
    
    private func moveToPreviousPhase() {
        let phases = BMadNativeProjectCreationView.BMadCreationPhase.allCases
        if let currentIndex = phases.firstIndex(of: currentPhase),
           currentIndex > 0 {
            currentPhase = phases[currentIndex - 1]
        }
    }
}

struct ReviewSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
    }
}

// MARK: - Extensions

extension BMadWorkflowType {
    var displayName: String {
        switch self {
        case .greenfieldFullstack:
            return "Greenfield Full-Stack"
        case .featureEnhancement:
            return "Feature Enhancement"
        case .bugFix:
            return "Bug Fix"
        case .codeRefactor:
            return "Code Refactor"
        case .documentationUpdate:
            return "Documentation Update"
        }
    }
    
    var description: String {
        switch self {
        case .greenfieldFullstack:
            return "Create a new project from scratch with full development lifecycle"
        case .featureEnhancement:
            return "Add new features to existing codebase"
        case .bugFix:
            return "Fix bugs and issues in existing code"
        case .codeRefactor:
            return "Restructure and optimize existing code"
        case .documentationUpdate:
            return "Update and improve project documentation"
        }
    }
}

#Preview {
    BMadNativeProjectCreationView(isPresented: .constant(true))
}