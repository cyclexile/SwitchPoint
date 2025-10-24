// MARK: - Device.swift
// Represents a physical or logical recording device participating in synchronization
// Author: Codex Agent

import Foundation

/// Enumerates supported device categories within the synchronization domain.
public enum DeviceType: String, Codable, Sendable, CaseIterable {
    case camera
    case audio
    case switcher
    case manual
}

/// Describes a recording device and its associated synchronization metadata.
public struct Device: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var type: DeviceType
    /// User-adjustable offset relative to the master timeline (seconds).
    public var offset: TimeInterval
    /// List of synchronization events captured for this device.
    public var events: [SyncEvent]

    public init(
        id: UUID = UUID(),
        name: String,
        type: DeviceType,
        offset: TimeInterval = 0,
        events: [SyncEvent] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.offset = offset
        self.events = events.sorted(by: { $0.timestamp < $1.timestamp })
    }
}

public extension Device {
    /// Returns the earliest timestamp present in the device events.
    var earliestEventDate: Date? { events.first?.timestamp }

    /// Returns the latest timestamp present in the device events.
    var latestEventDate: Date? { events.last?.timestamp }

    /// Adjusts the device offset by the provided delta.
    mutating func applyOffsetAdjustment(_ delta: TimeInterval) {
        offset += delta
    }
}
