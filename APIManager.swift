import Foundation

// MARK: - API Configuration

struct APIConfiguration {
    let baseURL: URL
    let paradigmEndpoint: String = "/api/paradigm/state"
    let memoryEndpoint: String = "/api/memory/entries"
    let beliefEndpoint: String = "/api/beliefs/nodes"
    let logicEndpoint: String = "/api/logic/entries"
    let healthEndpoint: String = "/api/health"
    
    static let `default` = APIConfiguration(
        baseURL: URL(string: "http://localhost:8000") ?? URL(fileURLWithPath: "")
    )
}

// MARK: - State Mapping Models

/// Request model for paradigm routing state
struct ParadigmStateRequest: Codable {
    let sessionId: String
    let queryType: String  // socratic, analytical, empathetic, etc.
    let timestamp: Date
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case queryType = "query_type"
        case timestamp
        case metadata
    }
}

/// Request model for congress engagement state
struct CongressStateRequest: Codable {
    let sessionId: String
    let congressEngaged: Bool
    let perspectiveCount: Int  // 0 (direct) or 4 (full debate)
    let perspectives: [PerspectiveStateRequest]?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case congressEngaged = "congress_engaged"
        case perspectiveCount = "perspective_count"
        case perspectives
        case timestamp
    }
}

/// Request model for individual perspective
struct PerspectiveStateRequest: Codable {
    let role: String  // advocate, skeptic, synthesizer, ethics
    let position: String
    let reasoning: String
    let strengthOfArgument: Double
    let callNumber: Int
    
    enum CodingKeys: String, CodingKey {
        case role
        case position
        case reasoning
        case strengthOfArgument = "strength_of_argument"
        case callNumber = "call_number"
    }
}

/// Request model for self-insights (ego state)
struct EgoStateRequest: Codable {
    let sessionId: String
    let selfInsights: [SelfInsightRequest]
    let reasoningPatterns: [String]  // Patterns observed in own reasoning
    let beliefAlignments: [BeliefsPatternRequest]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case selfInsights = "self_insights"
        case reasoningPatterns = "reasoning_patterns"
        case beliefAlignments = "belief_alignments"
        case timestamp
    }
}

/// Individual self-insight
struct SelfInsightRequest: Codable {
    let category: String  // reasoningPattern, growthArea, beliefAlignment, etc.
    let content: String
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case category
        case content
        case confidence
    }
}

/// Belief alignment from reasoning
struct BeliefsPatternRequest: Codable {
    let beliefStance: String
    let alignmentScore: Double  // -1 to 1: negative = conflict, positive = support
    let changeVector: String  // "strengthened", "challenged", "neutral"
    
    enum CodingKeys: String, CodingKey {
        case beliefStance = "belief_stance"
        case alignmentScore = "alignment_score"
        case changeVector = "change_vector"
    }
}

/// Request model for memory entries
struct MemoryEntryRequest: Codable {
    let sessionId: String
    let userQuery: String
    let sovernResponse: String
    let paradigmRouting: String
    let congressEngaged: Bool
    let humanInsights: [HumanInsightRequest]
    let selfInsights: [SelfInsightRequest]
    let learnedPatterns: [PatternRequest]
    let researchNotes: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case userQuery = "user_query"
        case sovernResponse = "sovern_response"
        case paradigmRouting = "paradigm_routing"
        case congressEngaged = "congress_engaged"
        case humanInsights = "human_insights"
        case selfInsights = "self_insights"
        case learnedPatterns = "learned_patterns"
        case researchNotes = "research_notes"
        case timestamp
    }
}

/// Human insight from interaction
struct HumanInsightRequest: Codable {
    let category: String
    let content: String
    let source: String?
    
    enum CodingKeys: String, CodingKey {
        case category
        case content
        case source
    }
}

/// Learned pattern
struct PatternRequest: Codable {
    let pattern: String
    let description: String
    let frequency: Double
    let evidence: [String]
    
    enum CodingKeys: String, CodingKey {
        case pattern
        case description
        case evidence
        case frequency
    }
}

/// Request model for belief updates
struct BeliefUpdateRequest: Codable {
    let beliefStance: String
    let domain: String
    let weight: Int
    let reasoning: String
    let revisionType: String  // challenge, strengthen, revise, weaken
    let revisionReason: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case beliefStance = "belief_stance"
        case domain
        case weight
        case reasoning
        case revisionType = "revision_type"
        case revisionReason = "revision_reason"
        case timestamp
    }
}

/// Request model for logic entries
struct LogicEntryRequest: Codable {
    let sessionId: String
    let userQuery: String
    let weight: Double
    let paradigmRouting: String
    let congressEngaged: Bool
    let perspectives: [PerspectiveStateRequest]?
    let reasoningSteps: [ReasoningStepRequest]
    let candidateResponses: [CandidateResponseRequest]
    let profoundInsights: [String]
    let finalResponse: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case userQuery = "user_query"
        case weight
        case paradigmRouting = "paradigm_routing"
        case congressEngaged = "congress_engaged"
        case perspectives
        case reasoningSteps = "reasoning_steps"
        case candidateResponses = "candidate_responses"
        case profoundInsights = "profound_insights"
        case finalResponse = "final_response"
        case timestamp
    }
}

/// Reasoning step
struct ReasoningStepRequest: Codable {
    let stepType: String  // analysis, concern, debate, insight, revision
    let content: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case stepType = "step_type"
        case content
        case timestamp
    }
}

/// Candidate response draft
struct CandidateResponseRequest: Codable {
    let draftNumber: Int
    let content: String
    let status: String  // rejected, selected, considering
    let rejectionReason: String?
    
    enum CodingKeys: String, CodingKey {
        case draftNumber = "draft_number"
        case content
        case status
        case rejectionReason = "rejection_reason"
    }
}

// MARK: - Response Models

struct SyncResponse: Codable {
    let success: Bool
    let message: String
    let data: [String: AnyCodable]?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
    }
}

struct HealthResponse: Codable {
    let status: String
    let version: String
    let timestamp: Date
}

// MARK: - AnyCodable Helper

enum AnyCodable: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case object([String: AnyCodable])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: AnyCodable].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case offline
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .unauthorized:
            return "Unauthorized: Invalid credentials"
        case .offline:
            return "Device is offline"
        case .timeout:
            return "Request timeout"
        case .unknown:
            return "Unknown error"
        }
    }
}

// MARK: - Sync Queue Item

struct SyncQueueItem: Codable, Identifiable {
    let id: UUID
    let type: String  // paradigm, memory, belief, logic
    let payload: String  // JSON-encoded request
    let timestamp: Date
    var retryCount: Int = 0
    var maxRetries: Int = 3
    
    var isRetryable: Bool {
        retryCount < maxRetries
    }
}

// MARK: - APIManager

/// Manages all backend communication with Python server
/// Handles state synchronization, offline queuing, and error recovery
class APIManager: NSObject, ObservableObject {
    @Published var isOnline = true
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncQueue: [SyncQueueItem] = []
    
    private let config: APIConfiguration
    private let session: URLSession
    private var networkMonitor: NetworkMonitor?
    private var sessionId: String
    
    // MARK: - Initialization
    
    init(configuration: APIConfiguration = .default) {
        self.config = configuration
        self.sessionId = UUID().uuidString
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 60
        sessionConfig.waitsForConnectivity = true
        
        self.session = URLSession(configuration: sessionConfig)
        
        super.init()
        
        // Set up network monitoring
        setupNetworkMonitoring()
        
        // Attempt to restore sync queue from persistent storage
        restoreSyncQueue()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor = NetworkMonitor()
        networkMonitor?.onStatusChanged = { [weak self] isOnline in
            DispatchQueue.main.async {
                self?.isOnline = isOnline
                if isOnline {
                    self?.processSyncQueue()
                }
            }
        }
    }
    
    // MARK: - Health Check
    
    func checkBackendHealth(completion: @escaping (Result<HealthResponse, APIError>) -> Void) {
        guard let url = URL(string: config.baseURL.absoluteString + config.healthEndpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let health = try decoder.decode(HealthResponse.self, from: data)
                completion(.success(health))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    // MARK: - Paradigm State Sync
    
    func syncParadigmState(
        queryType: String,
        metadata: [String: String]? = nil,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let request = ParadigmStateRequest(
            sessionId: sessionId,
            queryType: queryType,
            timestamp: Date(),
            metadata: metadata
        )
        
        syncRequest(request, endpoint: config.paradigmEndpoint) { result in
            completion(result.map { _ in () })
        }
    }
    
    // MARK: - Congress State Sync
    
    func syncCongressState(
        congressEngaged: Bool,
        perspectives: [CongressPerspective]? = nil,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let perspectiveRequests = perspectives?.map { perspective in
            PerspectiveStateRequest(
                role: perspective.role.rawValue,
                position: perspective.position,
                reasoning: perspective.reasoning,
                strengthOfArgument: perspective.strengthOfArgument,
                callNumber: perspective.callNumber
            )
        }
        
        let request = CongressStateRequest(
            sessionId: sessionId,
            congressEngaged: congressEngaged,
            perspectiveCount: perspectiveRequests?.count ?? 0,
            perspectives: perspectiveRequests,
            timestamp: Date()
        )
        
        syncRequest(request, endpoint: config.paradigmEndpoint) { result in
            completion(result.map { _ in () })
        }
    }
    
    // MARK: - Ego State Sync (Self-Insights)
    
    func syncEgoState(
        selfInsights: [Insight],
        reasoningPatterns: [String],
        beliefAlignments: [(stance: String, score: Double, vector: String)],
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let insightRequests = selfInsights.map { insight in
            SelfInsightRequest(
                category: insight.category.rawValue,
                content: insight.content,
                confidence: 0.8  // Default confidence
            )
        }
        
        let beliefRequests = beliefAlignments.map { item in
            BeliefsPatternRequest(
                beliefStance: item.stance,
                alignmentScore: item.score,
                changeVector: item.vector
            )
        }
        
        let request = EgoStateRequest(
            sessionId: sessionId,
            selfInsights: insightRequests,
            reasoningPatterns: reasoningPatterns,
            beliefAlignments: beliefRequests,
            timestamp: Date()
        )
        
        syncRequest(request, endpoint: config.paradigmEndpoint) { result in
            completion(result.map { _ in () })
        }
    }
    
    // MARK: - Memory Entry Sync
    
    func syncMemoryEntry(
        _ entry: MemoryEntry,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let humanInsights = entry.humanInsights.insights.map { insight in
            HumanInsightRequest(
                category: insight.category.rawValue,
                content: insight.content,
                source: insight.source
            )
        }
        
        let selfInsights = entry.selfInsights.insights.map { insight in
            SelfInsightRequest(
                category: insight.category.rawValue,
                content: insight.content,
                confidence: 0.8
            )
        }
        
        let patterns = entry.learnedPatterns.map { pattern in
            PatternRequest(
                pattern: pattern.pattern,
                description: pattern.description,
                frequency: pattern.frequency,
                evidence: pattern.evidence
            )
        }
        
        let request = MemoryEntryRequest(
            sessionId: sessionId,
            userQuery: entry.userQuery,
            sovernResponse: entry.sovernResponse,
            paradigmRouting: entry.paradigmRouting,
            congressEngaged: entry.congressEngaged,
            humanInsights: humanInsights,
            selfInsights: selfInsights,
            learnedPatterns: patterns,
            researchNotes: entry.researchNotes,
            timestamp: entry.timestamp
        )
        
        syncRequest(request, endpoint: config.memoryEndpoint) { result in
            completion(result.map { _ in () })
        }
    }

    // MARK: - Fetch single Memory Entry (for conflict resolution)

    func fetchMemoryEntry(
        id: UUID,
        completion: @escaping (Result<MemoryEntryRequest, APIError>) -> Void
    ) {
        guard let url = URL(string: config.baseURL.absoluteString + config.memoryEndpoint + "/" + id.uuidString) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(sessionId, forHTTPHeaderField: "X-Session-ID")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let entry = try decoder.decode(MemoryEntryRequest.self, from: data)
                    completion(.success(entry))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case 400...499:
                if let message = try? JSONDecoder().decode(["message": String].self, from: data)["message"] {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
                } else {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: "Client error")))
                }
            case 500...599:
                if let message = try? JSONDecoder().decode(["message": String].self, from: data)["message"] {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
                } else {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: "Server error")))
                }
            default:
                completion(.failure(.unknown))
            }
        }.resume()
    }
    
    // MARK: - Belief Update Sync
    
    func syncBeliefUpdate(
        stance: String,
        domain: String,
        weight: Int,
        reasoning: String,
        revisionType: String,
        revisionReason: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let request = BeliefUpdateRequest(
            beliefStance: stance,
            domain: domain,
            weight: weight,
            reasoning: reasoning,
            revisionType: revisionType,
            revisionReason: revisionReason,
            timestamp: Date()
        )
        
        syncRequest(request, endpoint: config.beliefEndpoint) { result in
            completion(result.map { _ in () })
        }
    }
    
    // MARK: - Logic Entry Sync
    
    func syncLogicEntry(
        _ entry: LogicEntry,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        let perspectiveRequests = entry.perspectives.map { perspective in
            PerspectiveStateRequest(
                role: perspective.role.rawValue,
                position: perspective.position,
                reasoning: perspective.reasoning,
                strengthOfArgument: perspective.strengthOfArgument,
                callNumber: perspective.callNumber
            )
        }
        
        let stepRequests = entry.reasoningSteps.map { step in
            ReasoningStepRequest(
                stepType: step.type.rawValue,
                content: step.content,
                timestamp: step.timestamp
            )
        }
        
        let responseRequests = entry.candidateResponses.map { response in
            CandidateResponseRequest(
                draftNumber: response.draftNumber,
                content: response.content,
                status: response.status.rawValue,
                rejectionReason: response.rejectionReason
            )
        }
        
        let request = LogicEntryRequest(
            sessionId: sessionId,
            userQuery: entry.userQuery,
            weight: entry.weight,
            paradigmRouting: entry.paradigmRouting,
            congressEngaged: entry.congressEngaged,
            perspectives: perspectiveRequests,
            reasoningSteps: stepRequests,
            candidateResponses: responseRequests,
            profoundInsights: entry.profoundInsights,
            finalResponse: entry.finalResponse,
            timestamp: entry.timestamp
        )
        
        syncRequest(request, endpoint: config.logicEndpoint) { result in
            completion(result.map { _ in () })
        }
    }
    
    // MARK: - Generic Sync Request
    
    private func syncRequest<T: Encodable>(
        _ requestBody: T,
        endpoint: String,
        completion: @escaping (Result<SyncResponse, APIError>) -> Void
    ) {
        guard isOnline else {
            // Queue for later processing
            if let encoded = try? JSONEncoder().encode(requestBody) {
                let jsonString = String(data: encoded, encoding: .utf8) ?? ""
                let queueItem = SyncQueueItem(
                    id: UUID(),
                    type: endpoint,
                    payload: jsonString,
                    timestamp: Date()
                )
                DispatchQueue.main.async {
                    self.syncQueue.append(queueItem)
                    self.saveSyncQueue()
                }
            }
            completion(.failure(.offline))
            return
        }
        
        guard let url = URL(string: config.baseURL.absoluteString + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Session-ID")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }
        
        DispatchQueue.main.async { self.isSyncing = true }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async { self?.isSyncing = false }
            }
            
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let syncResponse = try decoder.decode(SyncResponse.self, from: data)
                    DispatchQueue.main.async {
                        self?.lastSyncTime = Date()
                    }
                    completion(.success(syncResponse))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            case 401:
                completion(.failure(.unauthorized))
            case 400...499:
                if let message = try? JSONDecoder().decode(["message": String].self, from: data)["message"] {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
                } else {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: "Client error")))
                }
            case 500...599:
                if let message = try? JSONDecoder().decode(["message": String].self, from: data)["message"] {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
                } else {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: "Server error")))
                }
            default:
                completion(.failure(.unknown))
            }
        }.resume()
    }
    
    // MARK: - Sync Queue Management
    
    private func saveSyncQueue() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(syncQueue)
            UserDefaults.standard.set(data, forKey: "sovern_sync_queue")
        } catch {
            print("Failed to save sync queue: \(error)")
        }
    }
    
    private func restoreSyncQueue() {
        guard let data = UserDefaults.standard.data(forKey: "sovern_sync_queue") else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            syncQueue = try decoder.decode([SyncQueueItem].self, from: data)
        } catch {
            print("Failed to restore sync queue: \(error)")
        }
    }
    
    func processSyncQueue() {
        guard !syncQueue.isEmpty && isOnline else { return }
        
        for (index, item) in syncQueue.enumerated() {
            processQueueItem(item) { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.syncQueue.remove(at: index)
                        self?.saveSyncQueue()
                    }
                } else if item.isRetryable {
                    DispatchQueue.main.async {
                        self?.syncQueue[index].retryCount += 1
                        self?.saveSyncQueue()
                    }
                }
            }
        }
    }
    
    private func processQueueItem(_ item: SyncQueueItem, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: config.baseURL.absoluteString + item.type) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Session-ID")
        request.httpBody = item.payload.data(using: .utf8)
        
        session.dataTask(with: request) { data, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode ?? 0 < 300
            completion(success)
        }.resume()
    }
    
    func clearSyncQueue() {
        syncQueue.removeAll()
        UserDefaults.standard.removeObject(forKey: "sovern_sync_queue")
    }
}

// MARK: - Network Monitor (Simple Implementation)

class NetworkMonitor {
    var onStatusChanged: ((Bool) -> Void)?
    private var isConnected = true
    
    init() {
        // Placeholder: In production, use Network framework
        // For now, assume online unless explicitly set offline
        checkConnectivity()
    }
    
    private func checkConnectivity() {
        let url = URL(string: "https://www.google.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 2
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            let isConnected = (response as? HTTPURLResponse) != nil && error == nil
            if isConnected != self?.isConnected {
                self?.isConnected = isConnected
                DispatchQueue.main.async {
                    self?.onStatusChanged?(isConnected)
                }
            }
        }.resume()
    }
}
