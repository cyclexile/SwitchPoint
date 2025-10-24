// MARK: - FCPXMLExporterTests.swift
// Validates Final Cut Pro XML serialization of synchronized timelines
// Author: Codex Agent

import XCTest
@testable import SwitchPointCore

final class FCPXMLExporterTests: XCTestCase {
    func testExportProducesWellFormedDocument() throws {
        let baseDate = ISO8601DateFormatter().date(from: "2024-01-01T12:00:00Z")!
        let referenceDevice = Device(
            name: "Camera A",
            type: .camera,
            events: [
                SyncEvent(timestamp: baseDate, label: "Slate", sourceFile: URL(string: "file:///recordings/camA.mov")),
                SyncEvent(timestamp: baseDate.addingTimeInterval(4))
            ]
        )

        let secondaryDevice = Device(
            name: "Camera B",
            type: .camera,
            events: [
                SyncEvent(timestamp: baseDate.addingTimeInterval(0.5), label: "Cut"),
                SyncEvent(timestamp: baseDate.addingTimeInterval(4.5))
            ]
        )

        let synchronizer = TimelineSynchronizer(configuration: .init(referenceDeviceID: referenceDevice.id))
        let timeline = try synchronizer.synchronize(devices: [referenceDevice, secondaryDevice])

        let exporter = FCPXMLExporter(configuration: .init(frameRate: 24))
        let data = try exporter.export(timeline: timeline, devices: [referenceDevice, secondaryDevice])
        let xmlString = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(xmlString.contains("<fcpxml version=\"1.8\">"))
        XCTAssertTrue(xmlString.contains(referenceDevice.name))
        XCTAssertTrue(xmlString.contains("asset-\(secondaryDevice.id.uuidString)"))
        XCTAssertTrue(xmlString.contains("marker"))
    }

    func testExportFailsWhenTimelineSegmentMissingDevice() throws {
        let timeline = Timeline(segments: [
            TimelineSegment(
                deviceID: UUID(),
                start: Date(),
                end: Date().addingTimeInterval(10),
                offset: 0,
                events: []
            )
        ])

        let exporter = FCPXMLExporter()
        XCTAssertThrowsError(try exporter.export(timeline: timeline, devices: [])) { error in
            guard case FCPXMLExporter.ExportError.unknownDevice = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }
}
