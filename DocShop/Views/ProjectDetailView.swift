import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    
    var body: some View {
        ProjectCommandDashboardView(project: project)
    }
}

#Preview {
    ProjectDetailView(project: Project(
        name: "Sample Project",
        description: "A demo project for preview.",
        requirements: ProjectRequirements(
            targetLanguages: [.swift],
            sdkFeatures: [.authentication],
            documentationRequirements: [.apiReference],
            testingRequirements: [.unit],
            performanceBenchmarks: [.latency],
            projectName: "Sample Project",
            projectDescription: "A demo project for preview."
        ),
        documents: []
    ))
} 