import SwiftUI
import UniformTypeIdentifiers

struct DocumentDetailView: View {
    let document: DocumentMetaData
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var showOutline = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showOutline.toggle() }) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .help("Show Document Outline")
                    
                    Menu {
                        Button("Open in Browser") {
                            if let url = URL(string: document.sourceURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        Button("Copy Link") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(document.sourceURL, forType: .string)
                        }
                        Button("Export Content") {
                            saveToFile()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            // Document Header
            VStack(alignment: .leading, spacing: 12) {
                Text(document.displayTitle)
                    .font(.title)
                    .fontWeight(.bold)
                
                Button(action: {
                    if let url = URL(string: document.sourceURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.primary)
                        Text(document.sourceURL)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .underline()
                    }
                }
                .buttonStyle(.plain)
                
                HStack {
                    Text(document.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(document.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading document...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Failed to load document")
                        .font(.headline)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        loadContent()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                HStack(spacing: 0) {
                    // Main content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Enhanced markdown content with clickable links
                            MarkdownViewerView(content: content)
                                .padding()
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu("Export") {
                                Button("Copy to Clipboard") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(content, forType: .string)
                                }
                                
                                Button("Save As...") {
                                    saveToFile()
                                }
                                
                                Button("Open in External Editor") {
                                    openInExternalEditor()
                                }
                            }
                        }
                    }
                    
                    // Outline sidebar
                    if showOutline {
                        Divider()
                        DocumentOutlineView(document: document)
                            .frame(width: 300)
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showOutline)
            }
        }
        .onAppear {
            loadContent()
        }
        .glassy()
    }
    
    private func loadContent() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let fileURL = URL(fileURLWithPath: document.filePath)
                let loadedContent = try DocumentStorage.shared.loadDocument(at: fileURL)
                
                await MainActor.run {
                    self.content = loadedContent
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(document.displayTitle).md"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save file: \(error)")
                }
            }
        }
    }
    
    private func openInExternalEditor() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(document.displayTitle).md")
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Failed to open in external editor: \(error)")
        }
    }
}


#Preview {
    DocumentDetailView(
        document: DocumentMetaData(
            title: "Sample Document",
            sourceURL: "https://example.com",
            filePath: "/tmp/sample.md",
            fileSize: 1024
        )
    )
}
