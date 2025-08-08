import SwiftUI
import UniformTypeIdentifiers

struct ImprovedDocumentDetailView: View {
    let document: DocumentMetaData
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""
    @State private var showOutline = false
    @State private var scrollProxy: ScrollViewProxy?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with document info
            documentHeader
            
            Divider()
            
            // Main content area
            HStack(spacing: 0) {
                // Document content
                documentContentArea
                
                // Outline sidebar (if shown)
                if showOutline {
                    Divider()
                    outlineSidebar
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .onChange(of: document.id) {
            loadContent()
        }
    }
    
    private var documentHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Button(action: {
                        if let url = URL(string: document.sourceURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.caption)
                            Text(document.sourceURL)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { showOutline.toggle() }) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title3)
                    }
                    .help("Toggle Outline")
                    
                    Menu {
                        Button("Copy Content") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(content, forType: .string)
                        }
                        
                        Button("Copy Link") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(document.sourceURL, forType: .string)
                        }
                        
                        Button("Export as Markdown") {
                            exportDocument()
                        }
                        
                        Button("Open in Browser") {
                            if let url = URL(string: document.sourceURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            
            // Document metadata
            HStack {
                Label(document.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(document.formattedFileSize, systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if document.accessCount > 0 {
                    Label("\(document.accessCount) views", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var documentContentArea: some View {
        VStack(spacing: 0) {
            // Search bar
            if !content.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    TextField("Search in document...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.caption)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                
                Divider()
            }
            
            // Content display
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading document...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
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
                ScrollViewReader { proxy in
                    ScrollView {
                        ImprovedMarkdownRenderer(
                            content: content,
                            searchText: searchText
                        )
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }
        }
    }
    
    private var outlineSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Outline")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showOutline = false }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(extractHeadings(from: content), id: \.id) { heading in
                        Button(action: {
                            if let proxy = scrollProxy {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("heading-\(heading.id)", anchor: .top)
                                }
                            }
                        }) {
                            HStack {
                                Text(heading.title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .padding(.leading, CGFloat(heading.level - 1) * 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(width: 250)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .trailing))
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
                    
                    // Record access
                    var updatedDoc = document
                    updatedDoc.recordAccess()
                    DocLibraryIndex.shared.updateDocument(updatedDoc)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func exportDocument() {
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
    
    private func extractHeadings(from content: String) -> [SimpleDocumentHeading] {
        let lines = content.components(separatedBy: .newlines)
        var headings: [SimpleDocumentHeading] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("# ") {
                headings.append(SimpleDocumentHeading(
                    id: index,
                    level: 1,
                    title: String(trimmed.dropFirst(2))
                ))
            } else if trimmed.hasPrefix("## ") {
                headings.append(SimpleDocumentHeading(
                    id: index,
                    level: 2,
                    title: String(trimmed.dropFirst(3))
                ))
            } else if trimmed.hasPrefix("### ") {
                headings.append(SimpleDocumentHeading(
                    id: index,
                    level: 3,
                    title: String(trimmed.dropFirst(4))
                ))
            }
        }
        
        return headings
    }
}

struct ImprovedMarkdownRenderer: View {
    let content: String
    let searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseContent(), id: \.id) { element in
                renderElement(element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func parseContent() -> [ContentElement] {
        let lines = content.components(separatedBy: .newlines)
        var elements: [ContentElement] = []
        var currentParagraph = ""
        var inCodeBlock = false
        var codeContent = ""
        var codeLanguage = ""
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Handle code blocks
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    if !codeContent.isEmpty {
                        elements.append(ContentElement(
                            id: index,
                            type: .codeBlock,
                            content: codeContent.trimmingCharacters(in: .newlines),
                            language: codeLanguage
                        ))
                        codeContent = ""
                        codeLanguage = ""
                    }
                    inCodeBlock = false
                } else {
                    // Start code block
                    if !currentParagraph.isEmpty {
                        elements.append(ContentElement(
                            id: index,
                            type: .paragraph,
                            content: currentParagraph.trimmingCharacters(in: .newlines)
                        ))
                        currentParagraph = ""
                    }
                    codeLanguage = String(trimmed.dropFirst(3))
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                codeContent += line + "\n"
                continue
            }
            
            // Handle headings
            if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(ContentElement(id: index, type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(ContentElement(id: index, type: .heading3, content: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(ContentElement(id: index, type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(ContentElement(id: index, type: .heading2, content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    elements.append(ContentElement(id: index, type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(ContentElement(id: index, type: .heading1, content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    elements.append(ContentElement(id: index, type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(ContentElement(id: index, type: .listItem, content: String(trimmed.dropFirst(2))))
            } else if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(ContentElement(id: index, type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
            } else {
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += line
            }
        }
        
        // Add final paragraph if exists
        if !currentParagraph.isEmpty {
            elements.append(ContentElement(id: elements.count, type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
        }
        
        return elements
    }
    
    @ViewBuilder
    private func renderElement(_ element: ContentElement) -> some View {
        switch element.type {
        case .heading1:
            Text(element.content)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .id("heading-\(element.id)")
                
        case .heading2:
            Text(element.content)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .id("heading-\(element.id)")
                
        case .heading3:
            Text(element.content)
                .font(.title3)
                .fontWeight(.medium)
                .padding(.top, 4)
                .padding(.bottom, 2)
                .id("heading-\(element.id)")
                
        case .paragraph:
            Text(processInlineMarkdown(element.content))
                .font(.body)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                
        case .codeBlock:
            VStack(alignment: .leading, spacing: 4) {
                if !element.language.isEmpty {
                    HStack {
                        Text(element.language.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(element.content, forType: .string)
                        }
                        .font(.caption2)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(element.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                    .foregroundColor(.secondary)
                Text(processInlineMarkdown(element.content))
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(.leading, 8)
        }
    }
    
    private func processInlineMarkdown(_ text: String) -> AttributedString {
        // Simple inline markdown processing
        var attributedString = AttributedString(text)
        
        // Make **bold** text bold
        let boldPattern = #"\*\*(.*?)\*\*"#
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let boldText = String(text[range]).replacingOccurrences(of: "**", with: "")
                    if let attrRange = Range(match.range, in: attributedString) {
                        attributedString.replaceSubrange(attrRange, with: AttributedString(boldText))
                        if let newRange = attributedString.range(of: boldText) {
                            attributedString[newRange].font = .body.bold()
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
}

struct ContentElement {
    let id: Int
    let type: ContentType
    let content: String
    let language: String
    
    init(id: Int, type: ContentType, content: String, language: String = "") {
        self.id = id
        self.type = type
        self.content = content
        self.language = language
    }
    
    enum ContentType {
        case heading1, heading2, heading3
        case paragraph
        case codeBlock
        case listItem
    }
}

struct SimpleDocumentHeading {
    let id: Int
    let level: Int
    let title: String
}

#Preview {
    ImprovedDocumentDetailView(document: DocumentMetaData(
        title: "Sample Document",
        sourceURL: "https://example.com",
        filePath: "/tmp/sample.md",
        fileSize: 1024
    ))
}
