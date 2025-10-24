// MARK: - Timeline.swift
// Describes the master timeline and aligned device segments
// Author: Codex Agent

import Foundation

/// Represents a single track segment for a device within the master timeline.
public struct TimelineSegment: Codable, Identifiable, Sendable {
    public let id: UUID
    public let deviceID: UUID
    public let start: Date
    public let end: Date
    public var offset: TimeInterval
    public var events: [SyncEvent]

    public init(
        id: UUID = UUID(),
        deviceID: UUID,
        start: Date,
        end: Date,
        offset: TimeInterval,
        events: [SyncEvent]
    ) {
        self.id = id
        self.deviceID = deviceID
        self.start = start
        self.end = end
        self.offset = offset
        self.events = events.ordered()
    }
}

/// Represents the unified master timeline for synchronized playback.
public struct Timeline: Codable, Sendable {
    public var segments: [TimelineSegment]
    public var created: Date
    public var metadata: [String: String]

    public init(
        segments: [TimelineSegment] = [],
        created: Date = .now,
        metadata: [String: String] = [:]
    ) {
        self.segments = segments
        self.created = created
        self.metadata = metadata
    }

    /// Returns the global start and end dates for all segments.
    public var bounds: (start: Date, end: Date)? {
        guard let firstStart = segments.map(\.start).min(),
              let lastEnd = segments.map(\.end).max() else {
            return nil
        }
        return (start: firstStart, end: lastEnd)
    }
}
