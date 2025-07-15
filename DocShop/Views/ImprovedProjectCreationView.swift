import SwiftUI

struct ImprovedProjectCreationView: View {
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedLanguages: Set<ProgrammingLanguage> = []
    @State private var selectedFeatures: Set<SDKFeature> = []
    @State private var selectedDocs: Set<DocumentationType> = []
    @State private var selectedTests: Set<TestingType> = []
    @State private var selectedBenchmarks: Set<BenchmarkCriteria> = []
    @State private var isCreatingProject = false
    @State private var creationError: Error?
    @State private var showErrorAlert = false
    @State private var showAIConsultation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Project Info Section
                    projectInfoSection
                    
                    // AI Consultation Button
                    aiConsultationSection
                    
                    // Selection Sections
                    languageSelectionSection
                    featureSelectionSection
                    documentationSelectionSection
                    testingSelectionSection
                    benchmarkSelectionSection
                }
                .padding()
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isCreatingProject {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Create") {
                            createProject()
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
        .alert("Project Creation Failed", isPresented: $showErrorAlert, presenting: creationError) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showAIConsultation) {
            AIProjectConsultationView(
                projectName: name,
                projectDescription: description,
                onRecommendations: { recommendations in
                    applyAIRecommendations(recommendations)
                }
            )
        }
    }
    
    private var projectInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter project name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $description)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var aiConsultationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { showAIConsultation = true }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("Get AI Recommendations")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            Text("Not sure what to select? Let AI analyze your project and suggest the best options.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var languageSelectionSection: some View {
        CompactSelectionSection(
            title: "Programming Languages",
            icon: "chevron.left.forwardslash.chevron.right",
            items: ProgrammingLanguage.allCases,
            selectedItems: $selectedLanguages
        )
    }
    
    private var featureSelectionSection: some View {
        CompactSelectionSection(
            title: "SDK Features",
            icon: "gear.badge",
            items: SDKFeature.allCases,
            selectedItems: $selectedFeatures
        )
    }
    
    private var documentationSelectionSection: some View {
        CompactSelectionSection(
            title: "Documentation Types",
            icon: "doc.text",
            items: DocumentationType.allCases,
            selectedItems: $selectedDocs
        )
    }
    
    private var testingSelectionSection: some View {
        CompactSelectionSection(
            title: "Testing Requirements",
            icon: "checkmark.shield",
            items: TestingType.allCases,
            selectedItems: $selectedTests
        )
    }
    
    private var benchmarkSelectionSection: some View {
        CompactSelectionSection(
            title: "Performance Benchmarks",
            icon: "speedometer",
            items: BenchmarkCriteria.allCases,
            selectedItems: $selectedBenchmarks
        )
    }
    
    private func createProject() {
        let requirements = ProjectRequirements(
            targetLanguages: Array(selectedLanguages),
            sdkFeatures: Array(selectedFeatures),
            documentationRequirements: Array(selectedDocs),
            testingRequirements: Array(selectedTests),
            performanceBenchmarks: Array(selectedBenchmarks),
            projectName: name,
            projectDescription: description
        )

        Task {
            isCreatingProject = true
            do {
                _ = await AgentOrchestrator.shared.createProject(
                    from: [], // Will be populated from library selection
                    requirements: requirements
                )
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    creationError = error
                    showErrorAlert = true
                    isCreatingProject = false
                }
            }
        }
    }
    
    private func applyAIRecommendations(_ recommendations: AIProjectRecommendations) {
        selectedLanguages = Set(recommendations.recommendedLanguages)
        selectedFeatures = Set(recommendations.recommendedFeatures)
        selectedDocs = Set(recommendations.recommendedDocs)
        selectedTests = Set(recommendations.recommendedTests)
        selectedBenchmarks = Set(recommendations.recommendedBenchmarks)
    }
}

struct CompactSelectionSection<Item: RawRepresentable & Hashable & CaseIterable & Identifiable>: View 
where Item.RawValue == String, Item.AllCases == [Item], Item.ID == Item {
    let title: String
    let icon: String
    let items: [Item]
    @Binding var selectedItems: Set<Item>
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.primary)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if !selectedItems.isEmpty {
                        Text("\(selectedItems.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 8)
                ], spacing: 8) {
                    ForEach(items) { item in
                        Toggle(isOn: Binding(
                            get: { selectedItems.contains(item) },
                            set: { isSelected in
                                if isSelected {
                                    selectedItems.insert(item)
                                } else {
                                    selectedItems.remove(item)
                                }
                            }
                        )) {
                            Text(item.rawValue.capitalized)
                                .font(.subheadline)
                        }
                        .toggleStyle(.checkbox)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedItems.contains(item) ? .blue.opacity(0.1) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// AI Consultation View
struct AIProjectConsultationView: View {
    let projectName: String
    let projectDescription: String
    let onRecommendations: (AIProjectRecommendations) -> Void
    
    @State private var isAnalyzing = false
    @State private var recommendations: AIProjectRecommendations?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing your project...")
                            .font(.headline)
                        Text("AI is reviewing your project details to suggest the best configuration.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let recommendations = recommendations {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Recommendations")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            recommendationSection("Languages", items: recommendations.recommendedLanguages.map { $0.rawValue })
                            recommendationSection("Features", items: recommendations.recommendedFeatures.map { $0.rawValue })
                            recommendationSection("Documentation", items: recommendations.recommendedDocs.map { $0.rawValue })
                            recommendationSection("Testing", items: recommendations.recommendedTests.map { $0.rawValue })
                            recommendationSection("Benchmarks", items: recommendations.recommendedBenchmarks.map { $0.rawValue })
                            
                            if !recommendations.reasoning.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Reasoning")
                                        .font(.headline)
                                    Text(recommendations.reasoning)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        
                        Text("AI Project Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Let AI analyze your project and recommend the best languages, features, and configurations based on your description.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Start Analysis") {
                            startAnalysis()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("AI Consultation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                if let recommendations = recommendations {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            onRecommendations(recommendations)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func recommendationSection(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func startAnalysis() {
        isAnalyzing = true
        
        // Simulate AI analysis
        Task {
            await Task.sleep(2_000_000_000) // 2 seconds
            
            // Generate mock recommendations based on project description
            let mockRecommendations = generateMockRecommendations()
            
            await MainActor.run {
                self.recommendations = mockRecommendations
                self.isAnalyzing = false
            }
        }
    }
    
    private func generateMockRecommendations() -> AIProjectRecommendations {
        // This would be replaced with actual AI analysis
        let description = projectDescription.lowercased()
        
        var languages: [ProgrammingLanguage] = []
        var features: [SDKFeature] = [.authentication, .errorHandling]
        var docs: [DocumentationType] = [.apiReference, .gettingStarted]
        var tests: [TestingType] = [.unit]
        var benchmarks: [BenchmarkCriteria] = [.correctness]
        
        // Simple keyword-based recommendations
        if description.contains("ios") || description.contains("swift") || description.contains("apple") {
            languages.append(.swift)
        }
        if description.contains("web") || description.contains("javascript") || description.contains("browser") {
            languages.append(.javascript)
        }
        if description.contains("python") || description.contains("ml") || description.contains("data") {
            languages.append(.python)
        }
        
        if languages.isEmpty {
            languages = [.swift] // Default
        }
        
        return AIProjectRecommendations(
            recommendedLanguages: languages,
            recommendedFeatures: features,
            recommendedDocs: docs,
            recommendedTests: tests,
            recommendedBenchmarks: benchmarks,
            reasoning: "Based on your project description, I recommend these technologies and configurations for optimal development workflow."
        )
    }
}

struct AIProjectRecommendations {
    let recommendedLanguages: [ProgrammingLanguage]
    let recommendedFeatures: [SDKFeature]
    let recommendedDocs: [DocumentationType]
    let recommendedTests: [TestingType]
    let recommendedBenchmarks: [BenchmarkCriteria]
    let reasoning: String
}

#Preview {
    ImprovedProjectCreationView(isPresented: .constant(true))
}