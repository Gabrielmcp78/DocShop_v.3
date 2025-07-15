import SwiftUI

struct ProjectListView: View {
    @ObservedObject private var projectStorage = ProjectStorage.shared
    @Binding var selectedProject: Project?
    
    var body: some View {
        List(selection: $selectedProject) {
            ForEach(projectStorage.projects) { project in
                HStack {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .font(.headline)
                        Text(project.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let date = project.estimatedCompletion {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .tag(project as Project?)
            }
        }
        .glassy()
        .navigationTitle("Projects")
    }
}

#Preview {
    ProjectListView(selectedProject: .constant(nil))
} 