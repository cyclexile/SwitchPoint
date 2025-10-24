// MARK: - ManualSyncTool.swift
// Provides APIs for defining manual synchronization points
// Author: Codex Agent

import Foundation

/// Allows operators to define manual synchronization cues and adjustments.
public actor ManualSyncTool {
    private var events: [SyncEvent] = []

    public init() {}

    /// Adds a new manual sync event with optional label.
    public func addEvent(at timestamp: Date, label: String? = nil) {
        let event = SyncEvent(timestamp: timestamp, label: label)
        events.append(event)
        events.sort { $0.timestamp < $1.timestamp }
    }

    /// Returns all manual sync events in chronological order.
    public func allEvents() -> [SyncEvent] {
        events
    }

    /// Removes a specific sync event by identifier.
    public func removeEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }
}
