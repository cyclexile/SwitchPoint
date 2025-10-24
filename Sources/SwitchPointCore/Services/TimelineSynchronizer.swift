// MARK: - TimelineSynchronizer.swift
// Computes offsets and produces the master timeline
// Author: Codex Agent

import Foundation

/// Aligns device events into a master timeline by calculating offsets against a reference device.
public final class TimelineSynchronizer: Sendable {
    public struct Configuration: Sendable {
        public let referenceDeviceID: UUID
        public let tolerance: TimeInterval
        public let frameDuration: TimeInterval

        public init(referenceDeviceID: UUID, tolerance: TimeInterval = 0.04, frameDuration: TimeInterval = 1 / 24) {
            self.referenceDeviceID = referenceDeviceID
            self.tolerance = tolerance
            self.frameDuration = frameDuration
        }
    }

    private let configuration: Configuration
    private let logger = Logger(label: "TimelineSync")

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Generates a synchronized timeline for the provided devices.
    /// - Parameter devices: Device collection with captured events.
    /// - Returns: Master timeline with segments per device.
    public func synchronize(devices: [Device]) throws -> Timeline {
        guard let referenceDevice = devices.first(where: { $0.id == configuration.referenceDeviceID }) else {
            throw SynchronizerError.missingReferenceDevice
        }

        logger.info("📍 Sync started", metadata: ["reference": referenceDevice.name])

        let referenceEvents = referenceDevice.events.ordered()
        var segments: [TimelineSegment] = []

        for device in devices {
            let targetEvents = device.events.ordered()
            guard !targetEvents.isEmpty else { continue }

            let offset = try computeOffset(referenceEvents: referenceEvents, targetEvents: targetEvents) + device.offset
            let alignedEvents = targetEvents.map { event -> SyncEvent in
                let adjustedTimestamp = event.timestamp.addingTimeInterval(offset)
                return SyncEvent(id: event.id, timestamp: adjustedTimestamp, label: event.label, sourceFile: event.sourceFile)
            }

            if let start = alignedEvents.first?.timestamp, let end = alignedEvents.last?.timestamp {
                let segment = TimelineSegment(
                    deviceID: device.id,
                    start: start,
                    end: end,
                    offset: offset,
                    events: alignedEvents
                )
                segments.append(segment)
            }
        }

        let timeline = Timeline(segments: segments)
        logger.info("✅ Timeline generated", metadata: ["segments": "\(segments.count)"])
        return timeline
    }
}

public extension TimelineSynchronizer {
    enum SynchronizerError: Error, LocalizedError {
        case missingReferenceDevice
        case insufficientEvents

        public var errorDescription: String? {
            switch self {
            case .missingReferenceDevice:
                return "Reference device not present in device list."
            case .insufficientEvents:
                return "Not enough events to compute reliable offsets."
            }
        }
    }
}

private extension TimelineSynchronizer {
    func computeOffset(referenceEvents: [SyncEvent], targetEvents: [SyncEvent]) throws -> TimeInterval {
        guard !referenceEvents.isEmpty, !targetEvents.isEmpty else {
            throw TimelineSynchronizer.SynchronizerError.insufficientEvents
        }

        let referenceAnchors = referenceEvents.map(\.timestamp)
        let targetAnchors = targetEvents.map(\.timestamp)
        var offsets: [TimeInterval] = []

        for reference in referenceAnchors {
            guard let closest = targetAnchors.min(by: { abs($0.timeIntervalSince(reference)) < abs($1.timeIntervalSince(reference)) }) else {
                continue
            }
            let delta = closest.timeIntervalSince(reference)
            if abs(delta) <= configuration.tolerance {
                offsets.append(delta)
            }
        }

        if offsets.isEmpty, let firstTarget = targetAnchors.first, let firstReference = referenceAnchors.first {
            let delta = firstTarget.timeIntervalSince(firstReference)
            offsets.append(delta)
        }

        let average = offsets.reduce(0, +) / Double(offsets.count)
        return (average / configuration.frameDuration).rounded() * configuration.frameDuration
    }
}
