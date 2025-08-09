import SwiftUI

struct BMadWorkflowCreationView: View {
    @Binding var selectedType: BMadWorkflowType
    let onCreateWorkflow: (BMadWorkflowType, BMadContext) -> Void
    
    @State private var projectPath: String = ""
    @State private var targetFiles: [String] = []
    @State private var requirements: [String] = []
    @State private var constraints: [String] = []
    @State private var newRequirement: String = ""
    @State private var newConstraint: String = ""
    @State private var newTargetFile: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workflow Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(BMadWorkflowType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text(selectedType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Project Configuration") {
                    TextField("Project Path", text: $projectPath)
                        .onAppear {
                            projectPath = FileManager.default.currentDirectoryPath
                        }
                }
                
                Section("Target Files") {
                    ForEach(targetFiles, id: \.self) { file in
                        HStack {
                            Text(file)
                            Spacer()
                            Button("Remove") {
                                targetFiles.removeAll { $0 == file }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add target file", text: $newTargetFile)
                        Button("Add") {
                            if !newTargetFile.isEmpty {
                                targetFiles.append(newTargetFile)
                                newTargetFile = ""
                            }
                        }
                        .disabled(newTargetFile.isEmpty)
                    }
                }
                
                Section("Requirements") {
                    ForEach(requirements, id: \.self) { requirement in
                        HStack {
                            Text(requirement)
                            Spacer()
                            Button("Remove") {
                                requirements.removeAll { $0 == requirement }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add requirement", text: $newRequirement)
                        Button("Add") {
                            if !newRequirement.isEmpty {
                                requirements.append(newRequirement)
                                newRequirement = ""
                            }
                        }
                        .disabled(newRequirement.isEmpty)
                    }
                }
                
                Section("Constraints") {
                    ForEach(constraints, id: \.self) { constraint in
                        HStack {
                            Text(constraint)
                            Spacer()
                            Button("Remove") {
                                constraints.removeAll { $0 == constraint }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add constraint", text: $newConstraint)
                        Button("Add") {
                            if !newConstraint.isEmpty {
                                constraints.append(newConstraint)
                                newConstraint = ""
                            }
                        }
                        .disabled(newConstraint.isEmpty)
                    }
                }
                
                Section("Suggested Configuration") {
                    Button("Load DocShop Enhancement Config") {
                        loadDocShopEnhancementConfig()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Create Workflow")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createWorkflow()
                    }
                    .disabled(projectPath.isEmpty)
                }
            }
        }
    }
    
    private func loadDocShopEnhancementConfig() {
        selectedType = .featureEnhancement
        targetFiles = [
            "DocShop/Views/LibraryView.swift",
            "DocShop/Core/DocumentProcessor.swift",
            "DocShop/Models/IngestedDocument.swift"
        ]
        requirements = [
            "Implement comprehensive search functionality",
            "Add document export capabilities",
            "Enhance document processing pipeline",
            "Improve user interface responsiveness",
            "Add document tagging and categorization"
        ]
        constraints = [
            "Maintain SwiftUI compatibility",
            "Preserve existing data structures",
            "Ensure backward compatibility",
            "Follow Apple's design guidelines"
        ]
    }
    
    private func createWorkflow() {
        let context = BMadContext(
            projectPath: projectPath,
            targetFiles: targetFiles,
            requirements: requirements,
            constraints: constraints,
            metadata: [
                "created_by": "user",
                "creation_date": ISO8601DateFormatter().string(from: Date()),
                "workflow_type": selectedType.rawValue
            ]
        )
        
        onCreateWorkflow(selectedType, context)
    }
}

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
            return "Complete development workflow for new projects from scratch"
        case .featureEnhancement:
            return "Add new features or enhance existing functionality"
        case .bugFix:
            return "Identify and fix bugs in existing code"
        case .codeRefactor:
            return "Improve code structure and maintainability"
        case .documentationUpdate:
            return "Update and improve project documentation"
        }
    }
}

#Preview {
    BMadWorkflowCreationView(
        selectedType: .constant(.featureEnhancement),
        onCreateWorkflow: { _, _ in }
    )
}