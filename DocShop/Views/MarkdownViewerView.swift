import SwiftUI

struct MarkdownViewerView: View {
    let content: String
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search in document...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if content.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 38))
                                .foregroundColor(.secondary)
                            
                            Text("Document is empty")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        MarkdownContentView(content: content, searchText: searchText)
                            .padding()
                    }
                }
            }
        }
        .glassy()
    }
}

struct MarkdownContentView: View {
    let content: String
    let searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(parseMarkdown(content), id: \.id) { element in
                switch element.type {
                case .heading1:
                    Text(element.content)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                        
                case .heading2:
                    Text(element.content)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top)
                        
                case .heading3:
                    Text(element.content)
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.top)
                        
                case .paragraph:
                    Text(element.content)
                        .font(.body)
                        
                case .code:
                    Text(element.content)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        
                case .listItem:
                    HStack(alignment: .top) {
                        Text("-")
                            .font(.body)
                        Text(element.content)
                            .font(.body)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func parseMarkdown(_ markdown: String) -> [MarkdownElement] {
        let lines = markdown.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var currentParagraph = ""
        var inCodeBlock = false
        var codeContent = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Handle code blocks
            if trimmedLine.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    if !codeContent.isEmpty {
                        elements.append(MarkdownElement(type: .code, content: codeContent.trimmingCharacters(in: .newlines)))
                        codeContent = ""
                    }
                    inCodeBlock = false
                } else {
                    // Start code block
                    if !currentParagraph.isEmpty {
                        elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                        currentParagraph = ""
                    }
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                codeContent += line + "\n"
                continue
            }
            
            // Handle headings
            if trimmedLine.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading1, content: String(trimmedLine.dropFirst(2))))
            } else if trimmedLine.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading2, content: String(trimmedLine.dropFirst(3))))
            } else if trimmedLine.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading3, content: String(trimmedLine.dropFirst(4))))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .listItem, content: String(trimmedLine.dropFirst(2))))
            } else if trimmedLine.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
                    currentParagraph = ""
                }
            } else {
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += trimmedLine
            }
        }
        
        // Add remaining content
        if !currentParagraph.isEmpty {
            elements.append(MarkdownElement(type: .paragraph, content: currentParagraph.trimmingCharacters(in: .newlines)))
        }
        
        if inCodeBlock && !codeContent.isEmpty {
            elements.append(MarkdownElement(type: .code, content: codeContent.trimmingCharacters(in: .newlines)))
        }
        
        return elements
    }
}

struct MarkdownElement {
    let id = UUID()
    let type: MarkdownElementType
    let content: String
}

enum MarkdownElementType {
    case heading1, heading2, heading3, paragraph, code, listItem
}

#Preview {
    MarkdownViewerView(content: """
    # Sample Document
    
    This is a sample markdown document with various elements.
    
    ## Code Example
    
    ```swift
    func hello() {
        print("Hello, World!")
    }
    ```
    
    ## List Example
    
    - Item 1
    - Item 2
    - Item 3
    
    ### Conclusion
    
    This demonstrates the markdown viewer functionality.
    """)
}