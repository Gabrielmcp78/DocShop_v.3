/*
import XCTest

class AgentContextTypesTests: XCTestCase {
    
    // MARK: - AgentMessage Tests
    
    func testAgentMessageCreation() {
        // Given
        let from = AgentID.documentProcessor
        let to = AgentID.searchEngine
        let type = MessageType.dataRequest
        let payload = "Test payload".data(using: .utf8)!
        
        // When
        let message = AgentMessage(from: from, to: to, type: type, payload: payload)
        
        // Then
        XCTAssertEqual(message.from, from)
        XCTAssertEqual(message.to, to)
        XCTAssertEqual(message.type, type)
        XCTAssertEqual(message.payload, payload)
        XCTAssertEqual(message.priority, .normal)
        XCTAssertNil(message.correlationId)
        XCTAssertNil(message.expiresAt)
        XCTAssertFalse(message.isAcknowledged)
        XCTAssertEqual(message.deliveryAttempts, 0)
        XCTAssertNil(message.metadata)
    }
    
    func testAgentMessageResponse() {
        // Given
        let originalMessage = AgentMessage(
            from: AgentID.documentProcessor,
            to: AgentID.searchEngine,
            type: .dataRequest,
            payload: "Request data".data(using: .utf8)!
        )
        let responsePayload = "Response data".data(using: .utf8)!
        
        // When
        let responseMessage = originalMessage.createResponse(type: .dataResponse, payload: responsePayload)
        
        // Then
        XCTAssertEqual(responseMessage.from, originalMessage.to)
        XCTAssertEqual(responseMessage.to, originalMessage.from)
        XCTAssertEqual(responseMessage.type, .dataResponse)
        XCTAssertEqual(responseMessage.payload, responsePayload)
        XCTAssertEqual(responseMessage.correlationId, originalMessage.id)
    }
    
    func testAgentMessageAcknowledgment() {
        // Given
        let originalMessage = AgentMessage(
            from: AgentID.documentProcessor,
            to: AgentID.searchEngine,
            type: .dataRequest,
            payload: "Request data".data(using: .utf8)!
        )
        
        // When
        let ackMessage = originalMessage.createAcknowledgment()
        
        // Then
        XCTAssertEqual(ackMessage.from, originalMessage.to)
        XCTAssertEqual(ackMessage.to, originalMessage.from)
        XCTAssertEqual(ackMessage.type, .acknowledgment)
        XCTAssertEqual(ackMessage.payload, Data())
        XCTAssertEqual(ackMessage.correlationId, originalMessage.id)
    }
    
    func testAgentMessageDeliveryAttempt() {
        // Given
        let message = AgentMessage(
            from: AgentID.documentProcessor,
            to: AgentID.searchEngine,
            type: .dataRequest,
            payload: "Test payload".data(using: .utf8)!
        )
        
        // When
        let updatedMessage = message.withIncrementedDeliveryAttempt()
        
        // Then
        XCTAssertEqual(updatedMessage.deliveryAttempts, 1)
        
        // When incrementing again
        let twiceUpdatedMessage = updatedMessage.withIncrementedDeliveryAttempt()
        
        // Then
        XCTAssertEqual(twiceUpdatedMessage.deliveryAttempts, 2)
    }
    
    func testAgentMessageAcknowledged() {
        // Given
        let message = AgentMessage(
            from: AgentID.documentProcessor,
            to: AgentID.searchEngine,
            type: .dataRequest,
            payload: "Test payload".data(using: .utf8)!
        )
        
        // When
        let acknowledgedMessage = message.withAcknowledged()
        
        // Then
        XCTAssertTrue(acknowledgedMessage.isAcknowledged)
    }
    
    func testAgentMessageExpiration() {
        // Given
        let message = AgentMessage(
            from: AgentID.documentProcessor,
            to: AgentID.searchEngine,
            type: .dataRequest,
            payload: "Test payload".data(using: .utf8)!
        )
        
        // When - Set expiration to 1 second in the future
        let expiringMessage = message.withExpiration(seconds: 1)
        
        // Then
        XCTAssertNotNil(expiringMessage.expiresAt)
        XCTAssertFalse(expiringMessage.isExpired)
        
        // When - Wait for expiration
        Thread.sleep(forTimeInterval: 1.1)
        
        // Then
        XCTAssertTrue(expiringMessage.isExpired)
    }
    
    func testAgentMessageMetadata() {
        // Given
        let message = AgentMessage(
            from: AgentID.documentProcessor,
            to: AgentID.searchEngine,
            type: .dataRequest,
            payload: "Test payload".data(using: .utf8)!
        )
        
        // When
        let updatedMessage = message.withMetadata("key1", value: "value1")
        
        // Then
        XCTAssertNotNil(updatedMessage.metadata)
        XCTAssertEqual(updatedMessage.metadata?["key1"], "value1")
        
        // When adding another metadata
        let twiceUpdatedMessage = updatedMessage.withMetadata("key2", value: "value2")
        
        // Then
        XCTAssertEqual(twiceUpdatedMessage.metadata?["key1"], "value1")
        XCTAssertEqual(twiceUpdatedMessage.metadata?["key2"], "value2")
    }
    
    // MARK: - AgentContext Tests
    
    func testAgentContextCreation() {
        // Given
        let agentId = UUID()
        let agentType = AgentSpecialization.documentProcessor
        let capabilities = [AgentCapability.documentProcessing, AgentCapability.documentAnalysis]
        
        // When
        let context = AgentContext(
            agentID: agentId,
            agentType: agentType,
            capabilities: capabilities
        )
        
        // Then
        XCTAssertEqual(context.agentID, agentId)
        XCTAssertEqual(context.agentType, agentType)
        XCTAssertEqual(context.capabilities, capabilities)
        XCTAssertEqual(context.executionState, .initialized)
        XCTAssertNil(context.currentTask)
        XCTAssertNil(context.projectContext)
        XCTAssertTrue(context.relevantDocs.isEmpty)
        XCTAssertNil(context.documentRelationships)
        XCTAssertNil(context.messageQueue)
        XCTAssertNil(context.documentLocks)
        XCTAssertNil(context.sharedStateKeys)
        XCTAssertNil(context.coordinationStatus)
    }
    
    func testAgentContextMessageQueue() {
        // Given
        let context = AgentContext(
            agentID: UUID(),
            agentType: .documentProcessor,
            capabilities: [.documentProcessing]
        )
        
        let message = AgentMessage(
            from: .documentProcessor,
            to: .searchEngine,
            type: .dataRequest,
            payload: "Test payload".data(using: .utf8)!
        )
        
        // When
        let updatedContext = context.withQueuedMessage(message)
        
        // Then
        XCTAssertNotNil(updatedContext.messageQueue)
        XCTAssertEqual(updatedContext.messageQueue?.count, 1)
        XCTAssertEqual(updatedContext.messageQueue?.first?.id, message.id)
        
        // When adding another message
        let secondMessage = AgentMessage(
            from: .documentProcessor,
            to: .projectManager,
            type: .statusUpdate,
            payload: "Status update".data(using: .utf8)!
        )
        let twiceUpdatedContext = updatedContext.withQueuedMessage(secondMessage)
        
        // Then
        XCTAssertEqual(twiceUpdatedContext.messageQueue?.count, 2)
        
        // When removing a message
        let contextAfterRemoval = twiceUpdatedContext.withoutQueuedMessage(id: message.id)
        
        // Then
        XCTAssertEqual(contextAfterRemoval.messageQueue?.count, 1)
        XCTAssertEqual(contextAfterRemoval.messageQueue?.first?.id, secondMessage.id)
    }
    
    func testAgentContextDocumentLocks() {
        // Given
        let context = AgentContext(
            agentID: UUID(),
            agentType: .documentProcessor,
            capabilities: [.documentProcessing]
        )
        
        let documentId = UUID()
        let agentId = UUID()
        let lock = DocumentLock(
            documentId: documentId,
            lockingAgentId: agentId,
            lockType: .write
        )
        
        // When
        let updatedContext = context.withDocumentLock(lock)
        
        // Then
        XCTAssertNotNil(updatedContext.documentLocks)
        XCTAssertEqual(updatedContext.documentLocks?.count, 1)
        XCTAssertEqual(updatedContext.documentLocks?.first?.id, lock.id)
        
        // When removing the lock
        let contextAfterRemoval = updatedContext.withoutDocumentLock(id: lock.id)
        
        // Then
        XCTAssertEqual(contextAfterRemoval.documentLocks?.count, 0)
    }
    
    func testAgentContextSharedStateKeys() {
        // Given
        let context = AgentContext(
            agentID: UUID(),
            agentType: .documentProcessor,
            capabilities: [.documentProcessing]
        )
        
        let stateKey = SharedStateKey(
            key: "test.state.key",
            scope: .global,
            accessLevel: .readWrite
        )
        
        // When
        let updatedContext = context.withSharedStateKey(stateKey)
        
        // Then
        XCTAssertNotNil(updatedContext.sharedStateKeys)
        XCTAssertEqual(updatedContext.sharedStateKeys?.count, 1)
        XCTAssertEqual(updatedContext.sharedStateKeys?.first?.id, stateKey.id)
        
        // When removing the key
        let contextAfterRemoval = updatedContext.withoutSharedStateKey(id: stateKey.id)
        
        // Then
        XCTAssertEqual(contextAfterRemoval.sharedStateKeys?.count, 0)
    }
    
    func testAgentContextCoordinationStatus() {
        // Given
        let context = AgentContext(
            agentID: UUID(),
            agentType: .documentProcessor,
            capabilities: [.documentProcessing]
        )
        
        let status = CoordinationStatus(status: .coordinating)
        
        // When
        let updatedContext = context.withCoordinationStatus(status)
        
        // Then
        XCTAssertNotNil(updatedContext.coordinationStatus)
        XCTAssertEqual(updatedContext.coordinationStatus?.status, .coordinating)
        
        // When updating status
        let agent1 = UUID()
        let agent2 = UUID()
        let waitingStatus = status.withWaitingFor([agent1, agent2])
        let contextWithWaiting = updatedContext.withCoordinationStatus(waitingStatus)
        
        // Then
        XCTAssertEqual(contextWithWaiting.coordinationStatus?.status, .coordinating)
        XCTAssertEqual(contextWithWaiting.coordinationStatus?.waitingFor?.count, 2)
        XCTAssertEqual(contextWithWaiting.coordinationStatus?.waitingFor?.first, agent1)
    }
    
    func testAgentContextCollaboratingAgents() {
        // Given
        let context = AgentContext(
            agentID: UUID(),
            agentType: .documentProcessor,
            capabilities: [.documentProcessing]
        )
        
        let agent1 = UUID()
        
        // When
        let updatedContext = context.withCollaboratingAgent(agent1)
        
        // Then
        XCTAssertNotNil(updatedContext.collaboratingAgents)
        XCTAssertEqual(updatedContext.collaboratingAgents?.count, 1)
        XCTAssertEqual(updatedContext.collaboratingAgents?.first, agent1)
        
        // When adding the same agent again (should not duplicate)
        let twiceUpdatedContext = updatedContext.withCollaboratingAgent(agent1)
        
        // Then
        XCTAssertEqual(twiceUpdatedContext.collaboratingAgents?.count, 1)
        
        // When adding another agent
        let agent2 = UUID()
        let contextWithTwoAgents = twiceUpdatedContext.withCollaboratingAgent(agent2)
        
        // Then
        XCTAssertEqual(contextWithTwoAgents.collaboratingAgents?.count, 2)
        
        // When removing an agent
        let contextAfterRemoval = contextWithTwoAgents.withoutCollaboratingAgent(agent1)
        
        // Then
        XCTAssertEqual(contextAfterRemoval.collaboratingAgents?.count, 1)
        XCTAssertEqual(contextAfterRemoval.collaboratingAgents?.first, agent2)
    }
    
    // MARK: - DocumentLock Tests
    
    func testDocumentLockCreation() {
        // Given
        let documentId = UUID()
        let agentId = UUID()
        
        // When
        let lock = DocumentLock(
            documentId: documentId,
            lockingAgentId: agentId,
            lockType: .write,
            expiresIn: 60
        )
        
        // Then
        XCTAssertEqual(lock.documentId, documentId)
        XCTAssertEqual(lock.lockingAgentId, agentId)
        XCTAssertEqual(lock.lockType, .write)
        XCTAssertNotNil(lock.expiresAt)
        XCTAssertFalse(lock.isExpired)
        XCTAssertNil(lock.reason)
    }
    
    func testDocumentLockExpiration() {
        // Given
        let lock = DocumentLock(
            documentId: UUID(),
            lockingAgentId: UUID(),
            lockType: .read,
            expiresIn: 1
        )
        
        // Then
        XCTAssertFalse(lock.isExpired)
        
        // When - Wait for expiration
        Thread.sleep(forTimeInterval: 1.1)
        
        // Then
        XCTAssertTrue(lock.isExpired)
    }
    
    func testDocumentLockWithReason() {
        // Given
        let lock = DocumentLock(
            documentId: UUID(),
            lockingAgentId: UUID(),
            lockType: .process
        )
        
        // When
        let updatedLock = lock.withReason("Processing document for indexing")
        
        // Then
        XCTAssertEqual(updatedLock.reason, "Processing document for indexing")
    }
    
    func testDocumentLockExtendExpiration() {
        // Given
        let lock = DocumentLock(
            documentId: UUID(),
            lockingAgentId: UUID(),
            lockType: .write,
            expiresIn: 60
        )
        let originalExpiry = lock.expiresAt
        
        // When
        let extendedLock = lock.withExtendedExpiration(30)
        
        // Then
        XCTAssertNotNil(extendedLock.expiresAt)
        XCTAssertGreaterThan(extendedLock.expiresAt!.timeIntervalSince1970, originalExpiry!.timeIntervalSince1970)
    }
    
    // MARK: - CoordinationStatus Tests
    
    func testCoordinationStatusCreation() {
        // Given & When
        let status = CoordinationStatus()
        
        // Then
        XCTAssertEqual(status.status, .idle)
        XCTAssertNil(status.coordinatingWith)
        XCTAssertNil(status.waitingFor)
        XCTAssertNil(status.blockedBy)
        XCTAssertNil(status.lastCoordinationAt)
        XCTAssertNil(status.coordinationTimeout)
        XCTAssertFalse(status.isActive)
        XCTAssertFalse(status.isBlocked)
    }
    
    func testCoordinationStatusWithStatus() {
        // Given
        let status = CoordinationStatus()
        
        // When
        let updatedStatus = status.withStatus(.coordinating)
        
        // Then
        XCTAssertEqual(updatedStatus.status, .coordinating)
        XCTAssertNotNil(updatedStatus.lastCoordinationAt)
        XCTAssertTrue(updatedStatus.isActive)
        XCTAssertFalse(updatedStatus.isBlocked)
    }
    
    func testCoordinationStatusWithAgents() {
        // Given
        let status = CoordinationStatus(status: .coordinating)
        let agent1 = UUID()
        let agent2 = UUID()
        
        // When
        let updatedStatus = status.withCoordinatingAgents([agent1, agent2])
        
        // Then
        XCTAssertEqual(updatedStatus.coordinatingWith?.count, 2)
        XCTAssertEqual(updatedStatus.coordinatingWith?.first, agent1)
        XCTAssertEqual(updatedStatus.coordinatingWith?.last, agent2)
        
        // When
        let waitingStatus = updatedStatus.withWaitingFor([agent2])
        
        // Then
        XCTAssertEqual(waitingStatus.waitingFor?.count, 1)
        XCTAssertEqual(waitingStatus.waitingFor?.first, agent2)
        
        // When
        let blockedStatus = waitingStatus.withBlockedBy([agent1])
        
        // Then
        XCTAssertEqual(blockedStatus.status, .blocked)
        XCTAssertEqual(blockedStatus.blockedBy?.count, 1)
        XCTAssertEqual(blockedStatus.blockedBy?.first, agent1)
        XCTAssertTrue(blockedStatus.isBlocked)
    }
    
    func testCoordinationStatusTimeout() {
        // Given
        let status = CoordinationStatus(status: .waiting)
        
        // When
        let updatedStatus = status.withTimeout(1).withStatus(.waiting)
        let beforeTimeout = updatedStatus.isTimedOut
        
        // Then
        XCTAssertFalse(beforeTimeout)
        
        // When - Wait for timeout
        Thread.sleep(forTimeInterval: 1.1)
        let afterTimeout = updatedStatus.isTimedOut
        
        // Then
        XCTAssertTrue(afterTimeout)
    }
}

*/
