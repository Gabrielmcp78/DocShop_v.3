import SwiftUI

fileprivate extension Binding where Value == Bool {
    /// Creates a binding that toggles membership of a given value in a set.
    init<T: Hashable>(value: T, set: Binding<Set<T>>) {
        self.init(
            get: { set.wrappedValue.contains(value) },
            set: { isOn in
                if isOn { set.wrappedValue.insert(value) } else { set.wrappedValue.remove(value) }
            }
        )
    }
}

struct ProjectCreationView: View {
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Info")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                MultiSelectionSection(title: "Languages", items: ProgrammingLanguage.allCases, selectedItems: $selectedLanguages)
                MultiSelectionSection(title: "SDK Features", items: SDKFeature.allCases, selectedItems: $selectedFeatures)
                MultiSelectionSection(title: "Documentation", items: DocumentationType.allCases, selectedItems: $selectedDocs)
                MultiSelectionSection(title: "Testing", items: TestingType.allCases, selectedItems: $selectedTests)
                MultiSelectionSection(title: "Benchmarks", items: BenchmarkCriteria.allCases, selectedItems: $selectedBenchmarks)
            }
            .alert("Project Creation Failed", isPresented: $showErrorAlert, presenting: creationError) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.localizedDescription)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isCreatingProject {
                        ProgressView()
                    } else {
                    Button("Create") {
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
                                _ = try await AgentOrchestrator.shared.createProject(
                                    from: [], // Will be populated from library selection
                                    requirements: requirements
                                )
                                // On success, dismiss the view
                                isPresented = false
                            } catch {
                                // On failure, prepare and show an alert
                                creationError = error
                                showErrorAlert = true
                            }
                            isCreatingProject = false
                        }
                    }.disabled(name.isEmpty)
                    }
                }
            }
        }
    }
}

struct MultiSelectionSection<Item: RawRepresentable & Hashable & CaseIterable & Identifiable>: View where Item.RawValue == String, Item.AllCases == [Item], Item.ID == Item {
    let title: String
    let items: [Item]
    @Binding var selectedItems: Set<Item>

    var body: some View {
        Section(header: Text(title)) {
            ForEach(items) { item in
                Toggle(item.rawValue.capitalized, isOn: Binding(value: item, set: $selectedItems))
            }
        }
    }
}

#Preview {
    ProjectCreationView(isPresented: .constant(true))
} 