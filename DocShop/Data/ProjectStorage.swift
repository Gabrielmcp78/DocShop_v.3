import Foundation
import Combine

class ProjectStorage: ObservableObject {
    static let shared = ProjectStorage()

    @Published var projects: [Project] = []
    private let projectsFileURL: URL
    private let backupFileURL: URL
    private let storageQueue = DispatchQueue(label: "project.storage", qos: .userInitiated)

    private init() {
        let documentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("DocShop/Projects")

        try? FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)

        self.projectsFileURL = documentsPath.appendingPathComponent("projects.json")
        self.backupFileURL = documentsPath.appendingPathComponent("projects_backup.json")

        Task {
            self.projects = await loadProjects()
        }
    }

    func saveProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
        saveAllProjects()
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveAllProjects()
    }

    func loadProjects() async -> [Project] {
        guard FileManager.default.fileExists(atPath: projectsFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: projectsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Project].self, from: data)
        } catch {
            print("Failed to load projects, attempting recovery from backup: \(error)")
            return await recoverFromBackup()
        }
    }

    private func saveAllProjects() {
        storageQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(self.projects)

                if FileManager.default.fileExists(atPath: self.projectsFileURL.path) {
                    try? FileManager.default.copyItem(at: self.projectsFileURL, to: self.backupFileURL)
                }

                let tempURL = self.projectsFileURL.appendingPathExtension("tmp")
                try data.write(to: tempURL, options: .atomic)
                _ = try FileManager.default.replaceItemAt(self.projectsFileURL, withItemAt: tempURL)

            } catch {
                print("Failed to save projects: \(error)")
            }
        }
    }
    
    private func recoverFromBackup() async -> [Project] {
        guard FileManager.default.fileExists(atPath: backupFileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: backupFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let recoveredProjects = try decoder.decode([Project].self, from: data)
            
            // Restore the main file from backup
            try? data.write(to: projectsFileURL, options: .atomic)
            
            return recoveredProjects
        } catch {
            print("Failed to recover projects from backup: \(error)")
            return []
        }
    }
}

