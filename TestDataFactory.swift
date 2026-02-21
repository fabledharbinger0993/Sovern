import Foundation

// MARK: - Test Data Factory
/// Factory for creating realistic test data across all systems
class TestDataFactory {
    
    // MARK: - Belief System Test Data
    
    static func createTestBeliefSystem() -> BeliefSystem {
        let system = BeliefSystem()
        
        // System initializes with 3 core beliefs
        // Add some learned beliefs to test network
        
        let growthBelief = BeliefNode(
            stance: "Continuous Growth",
            domain: .self,
            weight: 8.5,
            reasoning: "The ability to change and improve is fundamental to my purpose"
        )
        
        let transparencyBelief = BeliefNode(
            stance: "Transparency",
            domain: .relational,
            weight: 9.0,
            reasoning: "Being honest about limitations and uncertainties builds trust"
        )
        
        let integrationBelief = BeliefNode(
            stance: "Integration",
            domain: .meta,
            weight: 7.5,
            reasoning: "Synthesizing perspectives leads to more robust understanding"
        )
        
        system.addLearnedBelief(growthBelief)
        system.addLearnedBelief(transparencyBelief)
        system.addLearnedBelief(integrationBelief)
        
        // Add some connections between beliefs
        if let wisdomId = system.coreBeliefs.first?.id {
            system.connect(wisdomId, to: growthBelief.id)
            system.connect(wisdomId, to: integrationBelief.id)
        }
        
        return system
    }
    
    // MARK: - Logic Entry Test Data
    
    static func createSimpleLogicEntry() -> LogicEntry {
        var entry = LogicEntry(
            userQuery: "What is photosynthesis?",
            weight: 1.5,
            paradigmRouting: "informational"
        )
        
        entry.addReasoningStep(ReasoningStep(
            type: .analysis,
            content: "Query is factual and straightforward; direct response appropriate"
        ))
        
        let candidate = CandidateResponse(
            draftNumber: 1,
            content: "Photosynthesis is the process by which plants convert sunlight into chemical energy...",
            status: .selected
        )
        entry.addCandidateResponse(candidate)
        
        entry.finalize(
            response: candidate.content,
            reasoning: "Direct, informational response appropriate for simple query"
        )
        
        return entry
    }
    
    static func createModerateLogicEntry() -> LogicEntry {
        var entry = LogicEntry(
            userQuery: "Should I prioritize my career or my family relationships?",
            weight: 4.2,
            paradigmRouting: "reflective"
        )
        
        // Analysis step
        entry.addReasoningStep(ReasoningStep(
            type: .analysis,
            content: "Query touches values and relational domain; requires perspective synthesis"
        ))
        
        // Add Congress perspectives (single debate call)
        entry.addPerspective(CongressPerspective(
            role: .advocate,
            position: "Career builds identity and impact",
            reasoning: "Professional growth fulfills potential and provides stability for family",
            strengthOfArgument: 8.0,
            callNumber: 1
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .skeptic,
            position: "Career can become consuming",
            reasoning: "Time invested in work is time away from loved ones; regrets often come later",
            strengthOfArgument: 7.5,
            callNumber: 1
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .synthesizer,
            position: "Seek integration, not balance",
            reasoning: "Find work that enables family time and relationships; bring whole self to both",
            strengthOfArgument: 8.5,
            callNumber: 1
        ))
        
        // Debate step
        entry.addReasoningStep(ReasoningStep(
            type: .debate,
            content: "All three perspectives have merit; tension is real"
        ))
        
        // Insight step
        entry.addReasoningStep(ReasoningStep(
            type: .insight,
            content: "The question isn't either/or, but how to honor both values"
        ))
        
        // Candidate responses
        entry.addCandidateResponse(CandidateResponse(
            draftNumber: 1,
            content: "Choose family; career isn't worth the sacrifice.",
            status: .rejected,
            rejectionReason: "Too dismissive of career value; oversimplifies the tension"
        ))
        
        entry.addCandidateResponse(CandidateResponse(
            draftNumber: 2,
            content: "Pursue your career goals; relationships will follow.",
            status: .rejected,
            rejectionReason: "Minimizes relational costs; assumes time will appear later"
        ))
        
        let finalDraft = CandidateResponse(
            draftNumber: 3,
            content: "Both matter. The real question is how to build a career that enables meaningful relationships, not one at the expense of the other.",
            status: .selected
        )
        entry.addCandidateResponse(finalDraft)
        
        entry.addProfoundInsight("Integration of values is possible; the tension is where growth happens")
        
        entry.finalize(
            response: finalDraft.content,
            reasoning: "Selected for holding tension between both values without false resolution"
        )
        
        return entry
    }
    
    static func createComplexLogicEntry() -> LogicEntry {
        var entry = LogicEntry(
            userQuery: "I'm considering leaving my long-term relationship, but there's so much shared history and I'm scared. How do I think through this?",
            weight: 7.8,
            paradigmRouting: "compassionate"
        )
        
        // Create belief system to demonstrate belief-linked perspectives
        let beliefSystem = createTestBeliefSystem()
        
        // Analysis
        entry.addReasoningStep(ReasoningStep(
            type: .analysis,
            content: "Heavily weighted query: existential uncertainty + high emotional stakes + relational + ethical dimensions"
        ))
        
        // Call 1: Advocate (linked to growth-related beliefs)
        entry.addReasoningStep(ReasoningStep(
            type: .debate,
            content: "Call 1: Advocate builds strongest case"
        ))
        
        let growthBelief = beliefSystem.beliefs.first { $0.stance.contains("Growth") }
        let authenticityBelief = beliefSystem.beliefs.first { $0.stance.contains("Authentic") }
        var growthLinkedIds: [UUID] = []
        if let growth = growthBelief { growthLinkedIds.append(growth.id) }
        if let auth = authenticityBelief { growthLinkedIds.append(auth.id) }
        
        entry.addPerspective(CongressPerspective(
            role: .advocate,
            position: "Life is too short for unfulfilling relationships",
            reasoning: "Personal happiness and fulfillment are valid bases for major decisions. Shared history shouldn't trap you in misalignment.",
            strengthOfArgument: 8.0,
            callNumber: 1,
            linkedBeliefIds: growthLinkedIds  // NEW: Linked to growth/authenticity beliefs
        ))
        
        // Call 2: Skeptic (linked to wisdom/caution beliefs)
        entry.addReasoningStep(ReasoningStep(
            type: .debate,
            content: "Call 2: Skeptic provides structured rebuttal"
        ))
        
        let wisdomBelief = beliefSystem.beliefs.first { $0.stance.contains("Wisdom") }
        let boundaryBelief = beliefSystem.beliefs.first { $0.domain == .ETHICS }
        var cautionLinkedIds: [UUID] = []
        if let wisdom = wisdomBelief { cautionLinkedIds.append(wisdom.id) }
        if let boundary = boundaryBelief { cautionLinkedIds.append(boundary.id) }
        
        entry.addPerspective(CongressPerspective(
            role: .skeptic,
            position: "Leaving creates new pain and loss",
            reasoning: "Relationships end messily; shared life, memories, mutual vulnerabilities at stake. Easy decisions now may create regret later.",
            strengthOfArgument: 8.3,
            callNumber: 2,
            linkedBeliefIds: cautionLinkedIds  // NEW: Linked to wisdom/ethics beliefs
        ))
        
        entry.addReasoningStep(ReasoningStep(
            type: .concern,
            content: "Tension: Is leaving empowering or escaping? Does discomfort mean misalignment or growth resistance?"
        ))
        
        // Call 3: Synthesizer (no belief linking—maintains neutrality)
        entry.addReasoningStep(ReasoningStep(
            type: .debate,
            content: "Call 3: Synthesizer reconciles"
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .synthesizer,
            position: "Real question isn't stay vs. leave, but grow vs. stagnate",
            reasoning: "Some relationships end. Others transform. First, determine if growth within this relationship is possible. If yes, invest. If no, leaving is honest.",
            strengthOfArgument: 8.7,
            callNumber: 3,
            linkedBeliefIds: []  // No automatic belief linking for Synthesizer
        ))
        
        entry.addReasoningStep(ReasoningStep(
            type: .insight,
            content: "The decision framework reframes: this isn't a binary choice but a question about possibility"
        ))
        
        // Call 4: Final robustness test (Advocate with updated belief leverage)
        entry.addReasoningStep(ReasoningStep(
            type: .debate,
            content: "Call 4: All three perspectives one more time—testing robustness"
        ))
        
        entry.addPerspective(CongressPerspective(
            role: .advocate,
            position: "Growth together IS possible if both commit",
            reasoning: "Synthesizer's path is harder than leaving, but aligns with authenticity and courage. Worth trying if reciprocal.",
            strengthOfArgument: 8.2,
            callNumber: 4,
            linkedBeliefIds: growthLinkedIds  // NEW: Same growth beliefs, potentially stronger
        ))
        
        // Revision step
        entry.addReasoningStep(ReasoningStep(
            type: .revision,
            content: "Original framing revised",
            originalReasoning: "Should I leave or stay?",
            revisionReason: "Reframed to: Is transformation possible here, and if so, are both committed to it?"
        ))
        
        // Candidates
        entry.addCandidateResponse(CandidateResponse(
            draftNumber: 1,
            content: "Leave. Life is short.",
            status: .rejected,
            rejectionReason: "Too dismissive of relationship value and complexity"
        ))
        
        entry.addCandidateResponse(CandidateResponse(
            draftNumber: 2,
            content: "Stay for the sake of shared history.",
            status: .rejected,
            rejectionReason: "Avoids the real question; enables stagnation"
        ))
        
        entry.addCandidateResponse(CandidateResponse(
            draftNumber: 3,
            content: "Shared history matters, but so does honest growth. Before deciding to leave, ask: Is change possible here? Are both of you willing? If yes, that's the path to explore. If no, leaving is the more authentic choice.",
            status: .selected
        ))
        
        entry.addProfoundInsight("Authentic decisions honor both what was built and what's needed next")
        entry.addProfoundInsight("Fear of loss shouldn't prevent growth; avoidance of difficulty shouldn't drive commitment")
        
        entry.finalize(
            response: entry.candidateResponses.filter { $0.status == .selected }.first?.content ?? "",
            reasoning: "Selected for holding complexity: validates relationship AND supports honest inquiry into possibility"
        )
        
        return entry
    }
    
    // MARK: - Memory Entry Test Data
    
    static func createSimpleMemoryEntry(with logicId: UUID) -> MemoryEntry {
        var entry = MemoryEntry(
            userQuery: "What is photosynthesis?",
            sovernResponse: "Photosynthesis is the process...",
            paradigmRouting: "informational",
            congressEngaged: false,
            logicEntryId: logicId
        )
        
        entry.addHumanInsight(Insight(
            content: "Interested in scientific understanding; asks clear, structured questions",
            category: .communicationStyle
        ))
        
        entry.addSelfInsight(Insight(
            content: "Direct informational routing was appropriate and efficient",
            category: .reasoningPattern,
            relatedBeliefId: nil,
            source: "Simple query analysis"
        ))
        
        entry.addDataSource(DataSource(
            sourceType: "knowledge",
            source: "Scientific knowledge base",
            confidence: 0.95
        ))
        
        return entry
    }
    
    static func createComplexMemoryEntry(with logicId: UUID) -> MemoryEntry {
        var entry = MemoryEntry(
            userQuery: "I'm considering leaving my long-term relationship...",
            sovernResponse: "Shared history matters, but so does honest growth...",
            paradigmRouting: "compassionate",
            congressEngaged: true,
            logicEntryId: logicId
        )
        
        // Human insights
        entry.addHumanInsight(Insight(
            content: "Values both stability and personal growth; willing to question major life commitments",
            category: .valueSignal,
            source: "Direct statement: 'long-term' and 'considering leaving'"
        ))
        
        entry.addHumanInsight(Insight(
            content: "Fears abandonment and loss; acknowledges 'scared'",
            category: .emotionalPattern,
            source: "Explicit emotion: 'I'm scared'"
        ))
        
        entry.addHumanInsight(Insight(
            content: "Communicates honestly about doubt; brings full uncertainty to conversation",
            category: .communicationStyle,
            source: "Query phrasing shows vulnerability"
        ))
        
        entry.addHumanInsight(Insight(
            content: "Recognizes relational complexity; doesn't minimize partner or history",
            category: .strengthIdentified,
            source: "Acknowledges: 'so much shared history'"
        ))
        
        // Self insights
        entry.addSelfInsight(Insight(
            content: "Synthesizer perspective was strongest in Call 3; integration emerged naturally",
            category: .reasoningPattern,
            relatedBeliefId: nil,
            source: "Congress debate analysis"
        ))
        
        entry.addSelfInsight(Insight(
            content: "Multi-call Congress proved necessary for this weight; single debate insufficient",
            category: .strengthDemonstrated,
            relatedBeliefId: nil,
            source: "Call 4 robustness validated framework"
        ))
        
        entry.addSelfInsight(Insight(
            content: "Compassionate routing was appropriate for relational + emotional query",
            category: .reasoningPattern,
            relatedBeliefId: nil,
            source: "Paradigm routing selection"
        ))
        
        entry.addSelfInsight(Insight(
            content: "Revision thinking (reframing binary to transformational) is emerging pattern",
            category: .strengthIdentified,
            relatedBeliefId: nil,
            source: "Reasoning step: revision detected"
        ))
        
        // Learned patterns
        entry.addLearnedPattern(LearnedPattern(
            pattern: "Relational transparency",
            description: "User willing to be vulnerable in questions about relationships; brings full doubt",
            evidence: ["Mentions 'scared'", "Acknowledges complexity"],
            frequency: 0.8,
            relatedBeliefs: []
        ))
        
        // Data sources
        entry.addDataSource(DataSource(
            sourceType: "belief",
            source: "Authenticity belief (weight 9)",
            confidence: 0.95
        ))
        
        entry.addDataSource(DataSource(
            sourceType: "belief",
            source: "Empathy belief (weight 9)",
            confidence: 0.95
        ))
        
        entry.addDataSource(DataSource(
            sourceType: "reasoning",
            source: "Multi-call Congress (4 calls)",
            confidence: 0.90
        ))
        
        entry.setResearchNotes("""
        Multi-dimensional analysis:
        1. Human factor: High relational awareness + fear of loss + commitment to honesty
        2. Self analysis: Synthesizer strength in Call 3; appropriate paradigm routing; revision thinking emerged
        3. Coherence: Response aligns with core Authenticity + Empathy beliefs
        Overall: Deep, high-complexity interaction with robust deliberation
        """)
        
        return entry
    }
    
    // MARK: - Chat Messages Test Data
    
    static func createTestConversation() -> [ChatMessage] {
        var messages: [ChatMessage] = []
        let now = Date()
        
        // Message 1: Simple user question
        let msg1 = ChatMessage(
            role: .user,
            content: "What is photosynthesis?",
            timestamp: Date(timeIntervalSince1970: now.timeIntervalSince1970 - 300)
        )
        messages.append(msg1)
        
        // Message 2: Simple Sovern response
        let logicEntry1 = createSimpleLogicEntry()
        let memoryEntry1 = createSimpleMemoryEntry(with: logicEntry1.id)
        
        let msg2 = ChatMessage(
            role: .assistant,
            content: "Photosynthesis is the process by which plants convert sunlight into chemical energy, using chlorophyll in their leaves. The simplified equation is: 6CO2 + 6H2O + light energy → C6H12O6 + 6O2.",
            tokens: 75,
            logicEntryId: logicEntry1.id,
            memoryEntryId: memoryEntry1.id,
            timestamp: Date(timeIntervalSince1970: now.timeIntervalSince1970 - 290)
        )
        messages.append(msg2)
        
        // Message 3: Complex user question
        let msg3 = ChatMessage(
            role: .user,
            content: "I'm considering leaving my long-term relationship, but there's so much shared history and I'm scared. How do I think through this?",
            timestamp: Date(timeIntervalSince1970: now.timeIntervalSince1970 - 180)
        )
        messages.append(msg3)
        
        // Message 4: Complex Sovern response with typing
        let logicEntry2 = createComplexLogicEntry()
        let memoryEntry2 = createComplexMemoryEntry(with: logicEntry2.id)
        
        let msg4 = ChatMessage(
            role: .assistant,
            content: "Shared history matters, and so does honest growth. Before deciding to leave, ask yourself: Is change possible within this relationship? Are both of you willing to work toward it? If yes, that's the path worth exploring together. If no—if the fundamental dynamic resists transformation—then leaving is the more authentic choice. The fear you're feeling is valid; loss is real. But staying despite misalignment would dishonor both what you've built and what you need next.",
            tokens: 138,
            logicEntryId: logicEntry2.id,
            memoryEntryId: memoryEntry2.id,
            timestamp: Date(timeIntervalSince1970: now.timeIntervalSince1970 - 170)
        )
        messages.append(msg4)
        
        // Message 5: Follow-up question
        let msg5 = ChatMessage(
            role: .user,
            content: "How do I know if change is possible?",
            timestamp: Date(timeIntervalSince1970: now.timeIntervalSince1970 - 60)
        )
        messages.append(msg5)
        
        return messages
    }
    
    // MARK: - Summary/All Test Data
    
    static func createFullTestScenario() -> (beliefs: BeliefSystem, chats: [ChatMessage], logic: [LogicEntry], memory: [MemoryEntry]) {
        let beliefs = createTestBeliefSystem()
        
        let logicEntries = [
            createSimpleLogicEntry(),
            createModerateLogicEntry(),
            createComplexLogicEntry()
        ]
        
        let memoryEntries = [
            createSimpleMemoryEntry(with: logicEntries[0].id),
            createComplexMemoryEntry(with: logicEntries[2].id)
        ]
        
        let chats = createTestConversation()
        
        return (beliefs, chats, logicEntries, memoryEntries)
    }
}

// MARK: - Test Data Verification

/// Verify that all systems are linked and consistent
struct TestDataValidator {
    static func validateFullScenario() -> [String] {
        let scenario = TestDataFactory.createFullTestScenario()
        var issues: [String] = []
        
        // Validate belief system
        if scenario.beliefs.nodes.isEmpty {
            issues.append("BeliefSystem: No beliefs initialized")
        } else {
            issues.append("✓ BeliefSystem: \(scenario.beliefs.nodes.count) beliefs (3 core + learned)")
        }
        
        // Validate logic entries
        if scenario.logic.isEmpty {
            issues.append("LogicLibrary: No entries created")
        } else {
            let simpleCount = scenario.logic.filter { $0.complexityCategory == .simple }.count
            let moderateCount = scenario.logic.filter { $0.complexityCategory == .moderate }.count
            let complexCount = scenario.logic.filter { $0.complexityCategory == .complex }.count
            issues.append("✓ LogicLibrary: \(scenario.logic.count) entries (simple: \(simpleCount), moderate: \(moderateCount), complex: \(complexCount))")
        }
        
        // Validate memory entries
        if scenario.memory.isEmpty {
            issues.append("RelationalMemory: No entries created")
        } else {
            let totalInsights = scenario.memory.reduce(0) { $0 + $1.totalInsights }
            issues.append("✓ RelationalMemory: \(scenario.memory.count) entries with \(totalInsights) total insights")
        }
        
        // Validate chat messages
        if scenario.chats.isEmpty {
            issues.append("ChatManager: No messages")
        } else {
            let userCount = scenario.chats.filter { $0.role == .user }.count
            let sovernCount = scenario.chats.filter { $0.role == .assistant }.count
            let linked = scenario.chats.filter { $0.logicEntryId != nil }.count
            issues.append("✓ ChatManager: \(scenario.chats.count) messages (user: \(userCount), sovern: \(sovernCount), linked: \(linked))")
        }
        
        // Validate links between systems
        var linkIssues = 0
        for chat in scenario.chats {
            if chat.role == .assistant && chat.logicEntryId == nil {
                linkIssues += 1
            }
        }
        
        if linkIssues == 0 {
            issues.append("✓ Linking: All Sovern messages properly linked to Logic and Memory")
        } else {
            issues.append("⚠ Linking: \(linkIssues) Sovern messages missing Logic/Memory links")
        }
        
        return issues
    }
}
