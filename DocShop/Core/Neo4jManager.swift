import Foundation

class Neo4jManager {
    static let shared = Neo4jManager()
    private init() {}
    
    // MARK: - Node Creation
    func createDocumentNode(_ document: IngestedDocument, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "CREATE (d:Document {id: $id, title: $title, author: $author, type: $type, tags: $tags, importedAt: $importedAt})"
        let params: [String: Any] = [
            "id": document.id.uuidString,
            "title": document.title,
            "author": document.author,
            "type": document.type.rawValue,
            "tags": document.tags.joined(separator: ","),
            "importedAt": ISO8601DateFormatter().string(from: document.importedAt)
        ]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    func createChunkNode(_ chunk: DocumentChunk, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "CREATE (c:Chunk {id: $id, documentID: $documentID, type: $type, content: $content, position: $position, metadataJSON: $metadataJSON, tags: $tags})"
        
        // Serialize metadata as JSON string
        var metadataJSON = "{}"
        if !chunk.metadata.isEmpty {
            if let data = try? JSONSerialization.data(withJSONObject: chunk.metadata),
               let jsonString = String(data: data, encoding: .utf8) {
                metadataJSON = jsonString
            }
        }
        
        let params: [String: Any] = [
            "id": chunk.id.uuidString,
            "documentID": chunk.documentID.uuidString,
            "type": chunk.type.rawValue,
            "content": chunk.content,
            "position": chunk.position,
            "metadataJSON": metadataJSON,
            "tags": chunk.tags.joined(separator: ",")
        ]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Relationship Creation
    func createHasChunkRelationship(documentID: UUID, chunkID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (d:Document {id: $docID}), (c:Chunk {id: $chunkID}) CREATE (d)-[:HAS_CHUNK]->(c)"
        let params: [String: Any] = [
            "docID": documentID.uuidString,
            "chunkID": chunkID.uuidString
        ]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    func createLinkedToRelationship(chunkID1: UUID, chunkID2: UUID, type: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (c1:Chunk {id: $id1}), (c2:Chunk {id: $id2}) CREATE (c1)-[:LINKED_TO {type: $type}]->(c2)"
        let params: [String: Any] = [
            "id1": chunkID1.uuidString,
            "id2": chunkID2.uuidString,
            "type": type
        ]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    func createSatisfiesRelationship(chunkID: UUID, requirementID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (c:Chunk {id: $chunkID}), (r:Requirement {id: $reqID}) CREATE (c)-[:SATISFIES]->(r)"
        let params: [String: Any] = [
            "chunkID": chunkID.uuidString,
            "reqID": requirementID.uuidString
        ]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Node/Relationship Update & Delete
    func updateNodeLabel(nodeID: UUID, label: String, value: String, nodeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (n:\(nodeType) {id: $id}) SET n.\(label) = $value"
        let params: [String: Any] = [
            "id": nodeID.uuidString,
            "value": value
        ]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    func deleteNode(nodeID: UUID, nodeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (n:\(nodeType) {id: $id}) DETACH DELETE n"
        let params: [String: Any] = ["id": nodeID.uuidString]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    func deleteRelationship(fromID: UUID, toID: UUID, relType: String, fromType: String, toType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (a:\(fromType) {id: $fromID})-[r:\(relType)]->(b:\(toType) {id: $toID}) DELETE r"
        let params: [String: Any] = ["fromID": fromID.uuidString, "toID": toID.uuidString]
        executeCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Search & Query
    func searchChunksByTag(tag: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (c:Chunk) WHERE $tag IN c.tags RETURN c"
        let params: [String: Any] = ["tag": tag]
        executeCypherQuery(cypher, params: params, completion: completion)
    }
    
    func fullTextSearchChunks(query: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "CALL db.index.fulltext.queryNodes('chunkContentIndex', $query) YIELD node RETURN node"
        let params: [String: Any] = ["query": query]
        executeCypherQuery(cypher, params: params, completion: completion)
    }
    
    func traceabilityMatrix(requirementID: UUID, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (r:Requirement {id: $reqID})<-[:SATISFIES]-(c:Chunk) RETURN c"
        let params: [String: Any] = ["reqID": requirementID.uuidString]
        executeCypherQuery(cypher, params: params, completion: completion)
    }
    
    func getRelatedChunks(chunkID: UUID, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (c:Chunk {id: $id})-[:LINKED_TO]->(related:Chunk) RETURN related"
        let params: [String: Any] = ["id": chunkID.uuidString]
        executeCypherQuery(cypher, params: params, completion: completion)
    }
    
    // MARK: - Knowledge Graph Fetch
    func getAllGraphNodesAndEdges(completion: @escaping (Result<([GraphNode], [GraphEdge]), Error>) -> Void) {
        let cypher = """
        MATCH (n) OPTIONAL MATCH (n)-[r]->(m) RETURN n, r, m
        """
        executeCypherQuery(cypher, params: [:]) { result in
            switch result {
            case .success(let dataArr):
                var nodes: [GraphNode] = []
                var edges: [GraphEdge] = []
                var nodeIDs = Set<String>()
                for row in dataArr {
                    if let n = row["n"] as? [String: Any], let node = GraphNode.fromNeo4j(n) {
                        if !nodeIDs.contains(node.id) {
                            nodes.append(node)
                            nodeIDs.insert(node.id)
                        }
                    }
                    if let m = row["m"] as? [String: Any], let node = GraphNode.fromNeo4j(m) {
                        if !nodeIDs.contains(node.id) {
                            nodes.append(node)
                            nodeIDs.insert(node.id)
                        }
                    }
                    if let r = row["r"] as? [String: Any],
                       let from = (row["n"] as? [String: Any])?["id"] as? String,
                       let to = (row["m"] as? [String: Any])?["id"] as? String,
                       let type = r["type"] as? String? ?? r["label"] as? String? ?? nil {
                        edges.append(GraphEdge(from: from, to: to, type: type))
                    }
                }
                completion(.success((nodes, edges)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - GraphNode/GraphEdge Structs
    struct GraphNode: Identifiable, Hashable {
        let id: String
        let label: String
        let type: String
        static func fromNeo4j(_ dict: [String: Any]) -> GraphNode? {
            guard let id = dict["id"] as? String else { return nil }
            let label = dict["title"] as? String ?? dict["name"] as? String ?? id
            let typeStr: String
            if let type = dict["type"] as? String {
                typeStr = type
            } else if let labels = dict["labels"] as? [String], let firstLabel = labels.first {
                typeStr = firstLabel
            } else {
                typeStr = "Unknown"
            }
            return GraphNode(id: id, label: label, type: typeStr)
        }
    }

    struct GraphEdge: Identifiable, Hashable {
        let id = UUID()
        let from: String
        let to: String
        let type: String
    }
    
    // MARK: - MCP Neo4j Integration
    private func executeCypher(_ cypher: String, params: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                // Execute cypher via MCP Neo4j server
                let result = try await executeNeo4jCommand(cypher: cypher, parameters: params)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func executeCypherQuery(_ cypher: String, params: [String: Any], completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        Task {
            do {
                // Execute cypher query via MCP Neo4j server and return results
                let results = try await executeNeo4jQuery(cypher: cypher, parameters: params)
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func executeNeo4jCommand(cypher: String, parameters: [String: Any]) async throws {
        // This would be replaced with actual MCP server call
        // For now, we'll simulate the MCP call structure
        let commandData: [String: Any] = [
            "cypher": cypher,
            "parameters": parameters
        ]
        
        // Placeholder for MCP server integration
        // In actual implementation, this would call the MCP Neo4j server
        print("Executing Neo4j command via MCP: \(cypher)")
    }
    
    private func executeNeo4jQuery(cypher: String, parameters: [String: Any]) async throws -> [[String: Any]] {
        // This would be replaced with actual MCP server call
        // For now, we'll simulate the MCP call structure
        let queryData: [String: Any] = [
            "cypher": cypher,
            "parameters": parameters
        ]
        
        // Placeholder for MCP server integration
        // In actual implementation, this would call the MCP Neo4j server and return results
        print("Executing Neo4j query via MCP: \(cypher)")
        return [] // Placeholder return
    }
} 

