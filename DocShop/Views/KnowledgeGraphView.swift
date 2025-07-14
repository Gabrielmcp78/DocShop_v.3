import SwiftUI
import VisualEffects

struct KnowledgeGraphView: View {
    @State private var isLoading = true
    @State private var error: String?
    @State private var nodes: [GraphNode] = []
    @State private var edges: [GraphEdge] = []
    @State private var selectedNode: GraphNode?
    @Namespace private var animation

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().padding(.bottom, 2)
            if isLoading {
                ProgressView("Loading knowledge graph...")
                    .padding()
            } else if let error = error {
                errorSection(error)
            } else {
                GraphCanvasView(nodes: nodes, edges: edges, selectedNode: $selectedNode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        VisualEffectBlur( material: .underWindowBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 8)
                    .padding(16)
            }
        }
        .onAppear(perform: loadGraph)
        .glassy()
        .navigationTitle("Knowledge Graph")
        .sheet(item: $selectedNode) { node in
            GraphNodeDetailView(node: node)
        }
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "circle.grid.cross")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("Knowledge Graph")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
        .padding([.top, .horizontal])
    }

    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
            Text(error).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func loadGraph() {
        isLoading = true
        error = nil
        // Replace fetchGraph with a query for all nodes and relationships
        Neo4jManager.shared.getAllGraphNodesAndEdges { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (fetchedNodes, fetchedEdges)):
                    self.nodes = fetchedNodes as! [GraphNode]
                    self.edges = fetchedEdges as! [GraphEdge]
                    self.isLoading = false
                case .failure(let err):
                    self.error = err.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Graph Data Models

struct GraphNode: Identifiable, Equatable {
    let id: String
    let label: String
    let type: String // e.g., "Document", "Chunk", "Tag"
    let metadata: [String: String]
}

struct GraphEdge: Identifiable, Equatable {
    let id: String
    let from: String
    let to: String
    let type: String // e.g., "HAS_CHUNK", "LINKED_TO"
}

// MARK: - Graph Canvas

struct GraphCanvasView: View {
    let nodes: [GraphNode]
    let edges: [GraphEdge]
    @Binding var selectedNode: GraphNode?
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(edges) { edge in
                    if let from = nodes.first(where: { $0.id == edge.from }),
                       let to = nodes.first(where: { $0.id == edge.to }) {
                        GraphEdgeView(from: from, to: to, geo: geo)
                    }
                }
                ForEach(nodes) { node in
                    GraphNodeView(node: node, geo: geo)
                        .onTapGesture { selectedNode = node }
                }
            }
        }
    }
}

struct GraphNodeView: View {
    let node: GraphNode
    let geo: GeometryProxy
    var body: some View {
        let pos = nodePosition(node: node, geo: geo)
        return VStack {
            Image(systemName: nodeIcon(for: node.type))
                .font(.title)
                .foregroundColor(nodeColor(for: node.type))
            Text(node.label)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .position(pos)
    }
    internal func nodePosition(node: GraphNode, geo: GeometryProxy) -> CGPoint {
        // Simple circular layout for demo; replace with force-directed for real graphs
        let idx = abs(node.id.hashValue) % 360
        let angle = Double(idx) * .pi / 180
        let radius = min(geo.size.width, geo.size.height) * 0.35
        let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }
    private func nodeIcon(for type: String) -> String {
        switch type {
        case "Document": return "doc.text"
        case "Chunk": return "square.stack.3d.up"
        case "Tag": return "tag"
        default: return "circle"
        }
    }
    private func nodeColor(for type: String) -> Color {
        switch type {
        case "Document": return .blue
        case "Chunk": return .purple
        case "Tag": return .orange
        default: return .gray
        }
    }
}

struct GraphEdgeView: View {
    let from: GraphNode
    let to: GraphNode
    let geo: GeometryProxy
    var body: some View {
        let fromPos = GraphNodeView(node: from, geo: geo).nodePosition(node: from, geo: geo)
        let toPos = GraphNodeView(node: to, geo: geo).nodePosition(node: to, geo: geo)
        return Path { path in
            path.move(to: fromPos)
            path.addLine(to: toPos)
        }
        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

// MARK: - Node Detail

struct GraphNodeDetailView: View {
    let node: GraphNode
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(node.label).font(.title2).fontWeight(.bold)
            Text("Type: \(node.type)").font(.caption).foregroundColor(.secondary)
            Divider()
            ForEach(node.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key.capitalized + ":").font(.caption).foregroundColor(.secondary)
                    Text(value).font(.body)
                }
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 320, minHeight: 200)
    }
} 

