import Foundation

// MARK: - Sync Timing Strategy

enum SyncTiming {
    case realTime           // Immediate (complex queries)
    case periodic           // Every 5 minutes (simple queries)
    case batched            // On app close (accumulate)
    case onDemand           // User manually triggers
}

// MARK: - Smart Sync Scheduler

/// Determines optimal sync timing based on query complexity and network state
class SmartSyncScheduler: ObservableObject {
    
    @Published var lastSyncTime: Date?
    @Published var pendingSyncCount: Int = 0
    
    private var periodicTimer: Timer?
    private let periodicInterval: TimeInterval = 300 // 5 minutes
    
    /// Determine sync timing for an interaction
    func determineSyncTiming(
        for logicEntry: LogicEntry,
        currentNetworkState isOnline: Bool
    ) -> SyncTiming {
        
        // If offline, always queue
        if !isOnline {
            return .batched  // Will queue and process when online
        }
        
        // Complex (weight > 5): Real-time sync
        if logicEntry.weight > 5.0 {
            return .realTime
        }
        
        // Medium (weight 3-5): Periodic sync
        if logicEntry.weight > 3.0 {
            return .periodic
        }
        
        // Simple (weight <= 3): Batched
        return .batched
    }
    
    /// Get description of timing strategy
    func timingDescription(for timing: SyncTiming) -> String {
        switch timing {
        case .realTime:
            return "Complex query — syncing immediately"
        case .periodic:
            return "Moderate query — syncing within 5 minutes"
        case .batched:
            return "Simple query — batching for later"
        case .onDemand:
            return "Manual sync triggered"
        }
    }
    
    /// Start periodic sync timer
    func startPeriodicSyncTimer(
        onTick: @escaping () -> Void
    ) {
        stopPeriodicSyncTimer()  // Clean up any existing timer
        
        periodicTimer = Timer.scheduledTimer(withTimeInterval: periodicInterval, repeats: true) { _ in
            onTick()
        }
    }
    
    /// Stop periodic sync timer
    func stopPeriodicSyncTimer() {
        periodicTimer?.invalidate()
        periodicTimer = nil
    }
    
    /// Record a sync event
    func recordSync() {
        self.lastSyncTime = Date()
        self.pendingSyncCount = max(0, self.pendingSyncCount - 1)
    }
    
    /// Add to pending sync queue
    func addPending() {
        self.pendingSyncCount += 1
    }
    
    /// Clear pending count
    func clearPending() {
        self.pendingSyncCount = 0
    }
    
    deinit {
        stopPeriodicSyncTimer()
    }
}

// MARK: - Integration Helper

struct SyncDecision {
    let timing: SyncTiming
    let description: String
    let shouldSyncNow: Bool
    
    static func make(
        for logicEntry: LogicEntry,
        isOnline: Bool,
        using scheduler: SmartSyncScheduler
    ) -> SyncDecision {
        let timing = scheduler.determineSyncTiming(for: logicEntry, currentNetworkState: isOnline)
        let description = scheduler.timingDescription(for: timing)
        let shouldSync = (timing == .realTime) && isOnline
        
        return SyncDecision(
            timing: timing,
            description: description,
            shouldSyncNow: shouldSync
        )
    }
}
