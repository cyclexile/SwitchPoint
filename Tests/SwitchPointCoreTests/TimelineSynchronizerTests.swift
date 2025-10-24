// MARK: - TimelineSynchronizerTests.swift
// Unit tests validating timeline synchronization accuracy
// Author: Codex Agent

import XCTest
@testable import SwitchPointCore

final class TimelineSynchronizerTests: XCTestCase {
    func testSynchronizerAlignsOffsetsWithinTolerance() throws {
        let referenceID = UUID()
        let baseDate = Date()
        let referenceDevice = Device(
            id: referenceID,
            name: "Reference",
            type: .camera,
            events: [
                SyncEvent(timestamp: baseDate),
                SyncEvent(timestamp: baseDate.addingTimeInterval(2))
            ]
        )

        let targetDevice = Device(
            name: "Camera B",
            type: .camera,
            events: [
                SyncEvent(timestamp: baseDate.addingTimeInterval(0.02)),
                SyncEvent(timestamp: baseDate.addingTimeInterval(2.02))
            ]
        )

        let synchronizer = TimelineSynchronizer(configuration: .init(referenceDeviceID: referenceID, tolerance: 0.05, frameDuration: 1 / 24))
        let timeline = try synchronizer.synchronize(devices: [referenceDevice, targetDevice])

        XCTAssertEqual(timeline.segments.count, 2)
        let targetSegment = try XCTUnwrap(timeline.segments.first { $0.deviceID == targetDevice.id })
        XCTAssertEqual(targetSegment.offset, 0, accuracy: 1 / 24)
    }
}
