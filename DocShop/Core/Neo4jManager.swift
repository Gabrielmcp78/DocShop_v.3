import Foundation

class Neo4jManager {
    static let shared = Neo4jManager()
    private let baseURL = URL(string: "http://localhost:7474/db/docshopgraphdb/tx/commit")!
    private let username = "neo4j"
    private let password = "NowVoyager2025!"
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
        runCypher(cypher, params: params, completion: completion)
    }
    
    func createChunkNode(_ chunk: DocumentChunk, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "CREATE (c:Chunk {id: $id, documentID: $documentID, type: $type, content: $content, position: $position, metadata: $metadata, tags: $tags})"
        let params: [String: Any] = [
            "id": chunk.id.uuidString,
            "documentID": chunk.documentID.uuidString,
            "type": chunk.type.rawValue,
            "content": chunk.content,
            "position": chunk.position,
            "metadata": chunk.metadata,
            "tags": chunk.tags.joined(separator: ",")
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Relationship Creation
    func createHasChunkRelationship(documentID: UUID, chunkID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (d:Document {id: $docID}), (c:Chunk {id: $chunkID}) CREATE (d)-[:HAS_CHUNK]->(c)"
        let params: [String: Any] = [
            "docID": documentID.uuidString,
            "chunkID": chunkID.uuidString
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func createLinkedToRelationship(chunkID1: UUID, chunkID2: UUID, type: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (c1:Chunk {id: $id1}), (c2:Chunk {id: $id2}) CREATE (c1)-[:LINKED_TO {type: $type}]->(c2)"
        let params: [String: Any] = [
            "id1": chunkID1.uuidString,
            "id2": chunkID2.uuidString,
            "type": type
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func createSatisfiesRelationship(chunkID: UUID, requirementID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (c:Chunk {id: $chunkID}), (r:Requirement {id: $reqID}) CREATE (c)-[:SATISFIES]->(r)"
        let params: [String: Any] = [
            "chunkID": chunkID.uuidString,
            "reqID": requirementID.uuidString
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Node/Relationship Update & Delete
    func updateNodeLabel(nodeID: UUID, label: String, value: String, nodeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (n:\(nodeType) {id: $id}) SET n.\(label) = $value"
        let params: [String: Any] = [
            "id": nodeID.uuidString,
            "value": value
        ]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func deleteNode(nodeID: UUID, nodeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (n:\(nodeType) {id: $id}) DETACH DELETE n"
        let params: [String: Any] = ["id": nodeID.uuidString]
        runCypher(cypher, params: params, completion: completion)
    }
    
    func deleteRelationship(fromID: UUID, toID: UUID, relType: String, fromType: String, toType: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cypher = "MATCH (a:\(fromType) {id: $fromID})-[r:\(relType)]->(b:\(toType) {id: $toID}) DELETE r"
        let params: [String: Any] = ["fromID": fromID.uuidString, "toID": toID.uuidString]
        runCypher(cypher, params: params, completion: completion)
    }
    
    // MARK: - Search & Query
    func searchChunksByTag(tag: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (c:Chunk) WHERE $tag IN c.tags RETURN c"
        let params: [String: Any] = ["tag": tag]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    func fullTextSearchChunks(query: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "CALL db.index.fulltext.queryNodes('chunkContentIndex', $query) YIELD node RETURN node"
        let params: [String: Any] = ["query": query]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    func traceabilityMatrix(requirementID: UUID, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (r:Requirement {id: $reqID})<-[:SATISFIES]-(c:Chunk) RETURN c"
        let params: [String: Any] = ["reqID": requirementID.uuidString]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    func getRelatedChunks(chunkID: UUID, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let cypher = "MATCH (c:Chunk {id: $id})-[:LINKED_TO]->(related:Chunk) RETURN related"
        let params: [String: Any] = ["id": chunkID.uuidString]
        runCypherQuery(cypher, params: params, completion: completion)
    }
    
    // MARK: - Knowledge Graph Fetch
    func getAllGraphNodesAndEdges(completion: @escaping (Result<([GraphNode], [GraphEdge]), Error>) -> Void) {
        let cypher = """
        MATCH (n) OPTIONAL MATCH (n)-[r]->(m) RETURN n, r, m
        """
        runCypherQuery(cypher, params: [:]) { result in
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
    
    // MARK: - Cypher Execution
    private func runCypher(_ cypher: String, params: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        let payload: [String: Any] = [
            "statements": [[
                "statement": cypher,
                "parameters": params
            ]]
        ]
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Neo4jManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Encoding error"])))
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Neo4jManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = json["errors"] as? [[String: Any]],
               !errors.isEmpty {
                let message = errors.first?["message"] as? String ?? "Unknown Neo4j error"
                completion(.failure(NSError(domain: "Neo4jManager", code: 2, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }
            completion(.success(()))
        }
        task.resume()
    }
    
    private func runCypherQuery(_ cypher: String, params: [String: Any], completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let payload: [String: Any] = [
            "statements": [[
                "statement": cypher,
                "parameters": params
            ]]
        ]
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Neo4jManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Encoding error"])))
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Neo4jManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let dataArr = results.first?["data"] as? [[String: Any]] {
                completion(.success(dataArr))
                return
            }
            completion(.failure(NSError(domain: "Neo4jManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])) )
        }
        task.resume()
    }
} 

