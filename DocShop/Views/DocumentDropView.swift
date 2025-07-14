//
//  DocumentDropView.swift
//  DocShop
//
//  Created by Gabriel McPherson on 6/28/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentDropView: View {
    @State private var urlString: String = ""
    @State private var selectedFile: URL?
    @State private var isImporting: Bool = false
    @State private var importError: String?
    @State private var isProcessing: Bool = false
    @State private var progress: Double = 0.0
    @State private var previewDocument: DocumentMetaData?
    @State private var previewContent: String = ""
    @State private var showPreview: Bool = false
    @State private var showDuplicateDialog: Bool = false
    @State private var duplicateDoc: DocumentMetaData?
    @State private var duplicateDecision: String? = nil
    @State private var isUpdating: Bool = false
    @State private var updateStatus: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text("Import Documentation")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // URL Import Section
            HStack(spacing: 12) {
                TextField("Paste documentation URL", text: $urlString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 320)
                Button("Import") { importFromURL() }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlString.isEmpty || isProcessing)
            }

            // File Import Section
            HStack(spacing: 12) {
                Button(action: { isImporting = true }) {
                    Label("Browse Files", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .fileImporter(isPresented: $isImporting, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first { selectedFile = url; importFromFile(url) }
                    case .failure(let error):
                        importError = error.localizedDescription
                    }
                }
                Text("or drag and drop a file below")
                    .foregroundColor(.secondary)
            }

            // Drag-and-drop area
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 80)
                .cornerRadius(18)
                .overlay(
                    Text("Drop files here")
                        .foregroundColor(.secondary)
                        .font(.headline)
                )
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }

            if isProcessing {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 320)
                Text("Processing...")
                    .font(.caption)
            }

            if let error = importError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.body)
            }

            if let status = updateStatus {
                Text(status)
                    .foregroundColor(.blue)
                    .font(.body)
            }
        }
        .padding(32)
        .glassy()
        .sheet(isPresented: $showPreview) {
            if let doc = previewDocument {
                DocumentPreviewModal(
                    document: doc,
                    content: previewContent,
                    onApprove: {
                        finalizeImport(doc)
                    },
                    onCancel: {
                        showPreview = false
                        previewDocument = nil
                        previewContent = ""
                    }
                )
            }
        }
        .sheet(isPresented: $showDuplicateDialog) {
            if let duplicate = duplicateDoc {
                DuplicateDecisionModal(
                    existing: duplicate,
                    onUpdate: { handleDuplicateDecision("update") },
                    onReplace: { handleDuplicateDecision("replace") },
                    onCancel: { handleDuplicateDecision("cancel") }
                )
            }
        }
    }

    // MARK: - Import Logic
    private func importFromURL() {
        guard !urlString.isEmpty else { return }
        isProcessing = true
        progress = 0.1
        importError = nil
        Task {
            do {
                let doc = try await DocumentProcessor.shared.importDocument(from: urlString)
                let content = try? DocumentStorage.shared.loadDocument(at: URL(fileURLWithPath: doc.filePath))
                await MainActor.run {
                    previewDocument = doc
                    previewContent = content ?? ""
                    showPreview = true
                    isProcessing = false
                }
            } catch let error as DocumentError {
                if case .duplicateDocument(_) = error, let existing = DocLibraryIndex.shared.documents.first(where: { $0.sourceURL == urlString }) {
                    duplicateDoc = existing
                    showDuplicateDialog = true
                    isProcessing = false
                } else {
                    importError = error.localizedDescription
                    isProcessing = false
                }
            } catch {
                importError = error.localizedDescription
                isProcessing = false
            }
        }
    }

    private func importFromFile(_ url: URL) {
        isProcessing = true
        progress = 0.1
        importError = nil
        Task {
            do {
                let doc = try await DocumentIngestionManager.shared.ingestFile(at: url)
                let meta = DocumentMetaData(title: doc.title, sourceURL: doc.url.absoluteString, filePath: doc.url.path, fileSize: 0)
                let content = try? DocumentStorage.shared.loadDocument(at: doc.url)
                await MainActor.run {
                    previewDocument = meta
                    previewContent = content ?? ""
                    showPreview = true
                    isProcessing = false
                }
            } catch {
                importError = error.localizedDescription
                isProcessing = false
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    importFromFile(url)
                }
            }
        }
        return true
    }

    private func finalizeImport(_ doc: DocumentMetaData) {
        DocLibraryIndex.shared.addDocument(doc)
        showPreview = false
        previewDocument = nil
        previewContent = ""
        updateStatus = "Document imported successfully."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { updateStatus = nil }
    }

    private func handleDuplicateDecision(_ decision: String) {
        guard let duplicate = duplicateDoc else { return }
        showDuplicateDialog = false
        if decision == "update" {
            isUpdating = true
            updateStatus = "Updating existing document..."
            Task {
                do {
                    // Load new content for comparison
                    let newDoc = try await DocumentProcessor.shared.importDocument(from: urlString, forceReimport: true, importMethod: .update)
                    var updated = duplicate
                    let newContent = try? DocumentStorage.shared.loadDocument(
                        at: URL(fileURLWithPath: newDoc.filePath)
                    )
                    SmartDuplicateHandler.shared.updateDocumentForReimport(&updated, newMethod: .update, newContent: newContent ?? "", jsRenderingUsed: newDoc.wasRenderedWithJS)
                    DocLibraryIndex.shared.updateDocument(updated)
                    updateStatus = "Document updated."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { updateStatus = nil }
                } catch {
                    updateStatus = "Update failed: \(error.localizedDescription)"
                }
                isUpdating = false
            }
        } else if decision == "replace" {
            DocLibraryIndex.shared.removeDocument(duplicate)
            if let doc = previewDocument {
                finalizeImport(doc)
            }
        }
        // If cancel, do nothing
        duplicateDoc = nil
        duplicateDecision = nil
    }
}

// MARK: - Preview Modal
struct DocumentPreviewModal: View {
    let document: DocumentMetaData
    let content: String
    let onApprove: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preview Document")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Title: \(document.title)")
                .font(.headline)
            if let summary = document.summary {
                Text("Summary: \(summary)")
            }
            if let tags = document.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(tags), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
            }
            Text("Source: \(document.sourceURL)")
                .font(.caption)
                .foregroundColor(.secondary)
            Divider()
            Text(content.prefix(600))
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(12)
                .padding(.bottom, 8)
            HStack {
                Button("Approve Import", action: onApprove)
                    .buttonStyle(.borderedProminent)
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(minWidth: 420, maxWidth: 600)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(radius: 18)
        .glassy()
    }
}

// MARK: - Duplicate Modal
struct DuplicateDecisionModal: View {
    let existing: DocumentMetaData
    let onUpdate: () -> Void
    let onReplace: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Duplicate Document Detected")
                .font(.title2)
                .fontWeight(.semibold)
            Text("A document with this source already exists: \(existing.title)")
                .font(.headline)
            Text("Imported: \(existing.formattedDate)")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                Button("Update Existing", action: onUpdate)
                    .buttonStyle(.borderedProminent)
                Button("Replace", action: onReplace)
                    .buttonStyle(.bordered)
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(minWidth: 420, maxWidth: 520)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(radius: 18)
        .glassy()
    }
}
