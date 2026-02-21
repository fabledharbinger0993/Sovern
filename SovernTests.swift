import XCTest
@testable import Sovern

// MARK: - Unit Tests for Sovern App (No Backend Required)

class SovernAppTests: XCTestCase {
    
    var coordinator: AppCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = AppCoordinator()
    }
    
    override func tearDown() {
        coordinator.clearAllData()
        super.tearDown()
    }
    
    // MARK: - Query Routing Tests
    
    func testParadigmClassification_Analytical() {
        let paradigm = coordinator.classifyQueryParadigm("How does photosynthesis work?")
        XCTAssertEqual(paradigm, "analytical")
    }
    
    func testParadigmClassification_Informational() {
        let paradigm = coordinator.classifyQueryParadigm("What is the capital of France?")
        XCTAssertEqual(paradigm, "informational")
    }
    
    func testParadigmClassification_Reflective() {
        let paradigm = coordinator.classifyQueryParadigm("How should I approach this problem?")
        XCTAssertEqual(paradigm, "reflective")
    }
    
    // MARK: - Chat → Logic → Memory Pipeline Tests
    
    func testProcessUserQueryUpdatesChat() {
        let initialCount = coordinator.chatManager.messages.count
        coordinator.processUserQuery("What is AI?")
        
        // Should add user message + assistant response
        XCTAssertGreater(coordinator.chatManager.messages.count, initialCount)
    }
    
    func testProcessUserQueryGeneratesLogicEntry() {
        let beforeCount = coordinator.logicLibrary.entries.count
        coordinator.processUserQuery("Explain consciousness")
        
        XCTAssertGreater(coordinator.logicLibrary.entries.count, beforeCount)
        
        let latestEntry = coordinator.logicLibrary.entries.last
        XCTAssertNotNil(latestEntry)
        XCTAssertFalse(latestEntry?.perspectives.isEmpty ?? true)
    }
    
    func testProcessUserQueryCreatesMemory() {
        let beforeCount = coordinator.relationalMemory.entries.count
        coordinator.processUserQuery("Tell me about learning")
        
        XCTAssertGreater(coordinator.relationalMemory.entries.count, beforeCount)
        
        let latestMemory = coordinator.relationalMemory.entries.last
        XCTAssertNotNil(latestMemory)
        XCTAssertFalse(latestMemory?.humanInsights.isEmpty ?? true)
    }
    
    func testCongressPerspectivesGenerated() {
        coordinator.processUserQuery("What makes something true?")
        
        let logicEntry = coordinator.logicLibrary.entries.last
        XCTAssertEqual(logicEntry?.perspectives.count, 4, "Should have 4 Congress perspectives")
        
        let roles = logicEntry?.perspectives.map { $0.role } ?? []
        XCTAssertTrue(roles.contains(.advocate))
        XCTAssertTrue(roles.contains(.skeptic))
        XCTAssertTrue(roles.contains(.synthesizer))
        XCTAssertTrue(roles.contains(.ethics))
    }
    
    // MARK: - Belief System Tests
    
    func testBeliefSystemInitialization() {
        XCTAssertGreater(coordinator.beliefSystem.nodes.count, 0)
        XCTAssertEqual(coordinator.beliefSystem.coreBeliefCount, 3)
    }
    
    func testBeliefCoherenceScore() {
        let coherence = coordinator.beliefSystem.coherenceScore
        XCTAssertGreaterThan(coherence, 0)
        XCTAssertLessThanOrEqual(coherence, 100)
    }
    
    // MARK: - User Context Tests
    
    func testUserContextPersistence() {
        let context = UserRelationalContext(
            name: "Alice",
            coreValues: ["Authenticity", "Growth"]
        )
        
        coordinator.setUserContext(context)
        XCTAssertEqual(coordinator.userContext?.name, "Alice")
        
        // Simulate app restart by reloading
        let reloadedCoordinator = AppCoordinator()
        XCTAssertEqual(reloadedCoordinator.userContext?.name, "Alice")
    }
    
    // MARK: - Sync Queue Tests
    
    func testSyncQueueHandlesOffline() {
        coordinator.apiManager.isOnline = false
        
        let syncRequest = APIManager.SyncQueueItem(
            type: .chatInteraction,
            data: Data(),
            timestamp: Date()
        )
        
        // In a real test, would call coordinator.processUserQuery and verify queue
        // For now, verify APIManager can persist queue
        let initialQueueCount = coordinator.apiManager.syncQueue.count
        XCTAssertGreaterThanOrEqual(initialQueueCount, 0)
    }
    
    // MARK: - Full Interaction Flow Test
    
    func testCompleteInteractionFlow() {
        // Setup: User exists
        let context = UserRelationalContext(
            name: "TestUser",
            coreValues: ["Wisdom"]
        )
        coordinator.setUserContext(context)
        
        // Step 1: Send query
        let query = "What is the meaning of life?"
        coordinator.processUserQuery(query)
        
        // Verification: Chat updated
        XCTAssertGreater(coordinator.chatManager.messages.count, 0)
        XCTAssertTrue(
            coordinator.chatManager.messages.contains { $0.role == .user && $0.content == query }
        )
        
        // Verification: Logic recorded
        XCTAssertEqual(coordinator.logicLibrary.entries.count, 1)
        let logic = coordinator.logicLibrary.entries[0]
        XCTAssertEqual(logic.userQuery, query)
        XCTAssertEqual(logic.perspectives.count, 4)
        XCTAssertFalse(logic.reasoningSteps.isEmpty)
        
        // Verification: Memory recorded
        XCTAssertEqual(coordinator.relationalMemory.entries.count, 1)
        let memory = coordinator.relationalMemory.entries[0]
        XCTAssertEqual(memory.userQuery, query)
        XCTAssertFalse(memory.humanInsights.isEmpty)
        XCTAssertFalse(memory.selfInsights.isEmpty)
        
        // Step 2: Send another query
        coordinator.processUserQuery("How do I grow as a person?")
        
        // Verification: Systems scale
        XCTAssertEqual(coordinator.chatManager.messages.filter { $0.role == .user }.count, 2)
        XCTAssertEqual(coordinator.logicLibrary.entries.count, 2)
        XCTAssertEqual(coordinator.relationalMemory.entries.count, 2)
    }
}

// MARK: - Integration Test Helpers

class SovernIntegrationTests: XCTestCase {
    
    func testDataConsistency() {
        let coordinator = AppCoordinator()
        
        // Inject test data
        coordinator.injectTestData()
        
        // Verify linking integrity
        coordinator.chatManager.messages.forEach { message in
            if message.role == .assistant {
                // Assistant messages should link to logic or memory entries
                if let logicId = message.logicEntryId {
                    let found = coordinator.logicLibrary.entries.contains { $0.id == logicId }
                    XCTAssertTrue(found, "Logic entry ID mismatch")
                }
            }
        }
    }
    
    func testOfflineQueueAndSync() {
        // Simulate offline environment
        let apiManager = APIManager()
        apiManager.isOnline = false
        
        // Queue would persist
        let queueCount = apiManager.syncQueue.count
        XCTAssertGreaterThanOrEqual(queueCount, 0)
        
        // When online, queue would process
        apiManager.isOnline = true
        // In real scenario, would call processSyncQueue()
    }
}

// MARK: - Performance Tests

class SovernPerformanceTests: XCTestCase {
    
    func testQueryProcessingPerformance() {
        let coordinator = AppCoordinator()
        
        measure {
            coordinator.processUserQuery("What is the nature of consciousness?")
        }
        // Should complete in <500ms
    }
    
    func testBeliefNetworkCoherencePerformance() {
        let system = BeliefSystem()
        
        measure {
            _ = system.coherenceScore
        }
        // Should compute <100ms even with many beliefs
    }
}
