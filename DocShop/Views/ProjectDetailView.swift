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
            targetLanguages: [ProgrammingLanguage.swift],
            sdkFeatures: [SDKFeature.authentication],
            documentationRequirements: [DocumentationType.apiReference],
            testingRequirements: [TestingType.unit],
            performanceBenchmarks: [BenchmarkCriteria.latency],
            projectName: "Sample Project",
            projectDescription: "A demo project for preview."
        ),
        documents: []
    ))
} 

