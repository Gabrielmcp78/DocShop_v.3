import SwiftUI

struct DocumentOutlineView: View {
    let document: DocumentMetaData
    @State private var outline: [OutlineItem] = []
    @State private var isLoading = true
    @State private var selectedItem: OutlineItem?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.primary)
                    Text("Document Outline")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Outline content
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating outline...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if outline.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No outline available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(outline, id: \.id, selection: $selectedItem) { item in
                        OutlineItemRow(item: item, selectedItem: $selectedItem)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Outline")
        }
        .onAppear {
            generateOutline()
        }
    }
    
    private func generateOutline() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let content = try String(contentsOf: URL(fileURLWithPath: document.filePath), encoding: .utf8)
                let generatedOutline = parseMarkdownOutline(content)
                
                await MainActor.run {
                    self.outline = generatedOutline
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.outline = []
                    self.isLoading = false
                }
            }
        }
    }
    
    private func parseMarkdownOutline(_ content: String) -> [OutlineItem] {
        let lines = content.components(separatedBy: .newlines)
        var items: [OutlineItem] = []
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("#") {
                let level = line.prefix(while: { $0 == "#" }).count
                let title = String(line.dropFirst(level).trimmingCharacters(in: .whitespaces))
                
                if !title.isEmpty {
                    items.append(OutlineItem(
                        id: UUID(),
                        title: title,
                        level: level,
                        lineNumber: index + 1,
                        type: .heading
                    ))
                }
            } else if line.hasPrefix("```") {
                let language = String(line.dropFirst(3).trimmingCharacters(in: .whitespaces))
                items.append(OutlineItem(
                    id: UUID(),
                    title: language.isEmpty ? "Code Block" : "\(language) Code",
                    level: 0,
                    lineNumber: index + 1,
                    type: .codeBlock
                ))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("1. ") {
                let title = String(line.dropFirst(2).trimmingCharacters(in: .whitespaces))
                if !title.isEmpty {
                    items.append(OutlineItem(
                        id: UUID(),
                        title: title,
                        level: 0,
                        lineNumber: index + 1,
                        type: .listItem
                    ))
                }
            }
        }
        
        return items
    }
}

struct OutlineItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let level: Int
    let lineNumber: Int
    let type: OutlineItemType
}

enum OutlineItemType {
    case heading
    case codeBlock
    case listItem
    case table
}

struct OutlineItemRow: View {
    let item: OutlineItem
    @Binding var selectedItem: OutlineItem?
    
    var body: some View {
        HStack {
            // Indentation for headings
            if item.type == .heading {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: CGFloat(max(0, item.level - 1)) * 12)
            }
            
            // Icon
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.caption)
                .frame(width: 16)
            
            // Title
            Text(item.title)
                .font(item.type == .heading ? .subheadline : .caption)
                .fontWeight(item.type == .heading ? .medium : .regular)
                .lineLimit(1)
            
            Spacer()
            
            // Line number
            Text("\(item.lineNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .background(selectedItem?.id == item.id ? Color.primary.opacity(0.15) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            selectedItem = item
        }
    }
    
    private var iconName: String {
        switch item.type {
        case .heading:
            return "number.circle"
        case .codeBlock:
            return "curlybraces"
        case .listItem:
            return "list.bullet"
        case .table:
            return "tablecells"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .heading:
            return .primary
        case .codeBlock:
            return .green
        case .listItem:
            return .orange
        case .table:
            return .purple
        }
    }
}

#Preview {
    DocumentOutlineView(document: DocumentMetaData(
        title: "Sample Document",
        sourceURL: "https://example.com",
        filePath: "/tmp/sample.md",
        fileSize: 1024,
        summary: "A sample document"
    ))
}