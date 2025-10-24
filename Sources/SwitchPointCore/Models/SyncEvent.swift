// MARK: - SyncEvent.swift
// Represents a synchronization point captured from a device or manual input
// Author: Codex Agent

import Foundation

/// Defines a synchronization event derived from source media or manual input.
public struct SyncEvent: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public var label: String?
    public var sourceFile: URL?

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        label: String? = nil,
        sourceFile: URL? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.label = label
        self.sourceFile = sourceFile
    }
}

public extension Array where Element == SyncEvent {
    /// Returns events ordered by their timestamp ascending.
    func ordered() -> [SyncEvent] { sorted(by: { $0.timestamp < $1.timestamp }) }
}
