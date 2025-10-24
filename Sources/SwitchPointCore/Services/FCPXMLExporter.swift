// MARK: - FCPXMLExporter.swift
// Serializes synchronized timelines into Final Cut Pro compatible XML documents
// Author: Codex Agent

import Foundation

/// Generates Final Cut Pro XML documents from a synchronized timeline.
public struct FCPXMLExporter: Sendable {
    public struct Configuration: Sendable {
        public let frameRate: Int
        public let eventName: String
        public let projectName: String
        public let libraryName: String
        public let includeMarkers: Bool

        public init(
            frameRate: Int = 24,
            eventName: String = "SwitchPoint Sync",
            projectName: String = "Master Timeline",
            libraryName: String = "SwitchPoint Library",
            includeMarkers: Bool = true
        ) {
            precondition(frameRate > 0, "Frame rate must be greater than zero")
            self.frameRate = frameRate
            self.eventName = eventName
            self.projectName = projectName
            self.libraryName = libraryName
            self.includeMarkers = includeMarkers
        }

        var frameDuration: TimeInterval { 1.0 / Double(frameRate) }
    }

    public enum ExportError: Error, LocalizedError {
        case emptyTimeline
        case unknownDevice(UUID)

        public var errorDescription: String? {
            switch self {
            case .emptyTimeline:
                return "Timeline has no segments to export."
            case .unknownDevice(let id):
                return "Timeline references a device that is not present in the export context: \(id.uuidString)."
            }
        }
    }

    private let configuration: Configuration
    private let logger: Logger

    public init(configuration: Configuration = .init(), logger: Logger = Logger(label: "FCPXMLExporter")) {
        self.configuration = configuration
        self.logger = logger
    }

    /// Generates an FCPXML document for the provided timeline and devices.
    /// - Parameters:
    ///   - timeline: The synchronized timeline to export.
    ///   - devices: Device metadata to enrich exported assets.
    /// - Returns: Raw XML data suitable for writing to disk.
    public func export(timeline: Timeline, devices: [Device]) throws -> Data {
        logger.info("📤 FCPXML export started", metadata: ["segments": "\(timeline.segments.count)"])

        guard let bounds = timeline.bounds else {
            throw ExportError.emptyTimeline
        }

        let deviceLookup = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
        let frameDurationString = "1/\(configuration.frameRate)s"
        let timelineDuration = bounds.end.timeIntervalSince(bounds.start)
        let sequenceDuration = timecodeString(for: timelineDuration)

        var resourceEntries: [String] = []
        var spineEntries: [String] = []
        resourceEntries.append("    <format id=\"r1\" name=\"SwitchPoint Format\" frameDuration=\"\(frameDurationString)\" colorSpace=\"sRGB\"/>")

        for segment in timeline.segments.sorted(by: { $0.start < $1.start }) {
            guard let device = deviceLookup[segment.deviceID] else {
                throw ExportError.unknownDevice(segment.deviceID)
            }

            let assetID = "asset-\(segment.deviceID.uuidString)"
            let clipName = device.name
            let clipDuration = timecodeString(for: segment.end.timeIntervalSince(segment.start))
            let clipOffset = timecodeString(for: segment.start.timeIntervalSince(bounds.start))
            let clipStart = "0s"
            let sourceURL = segment.events.compactMap(\.sourceFile).first?.absoluteString ?? ""
            let sanitizedSource = sourceURL.isEmpty ? nil : sourceURL

            var assetAttributes = [
                "id=\"\(assetID)\"",
                "name=\"\(clipName.xmlEscaped())\"",
                "start=\"0s\"",
                "duration=\"\(clipDuration)\"",
                "hasVideo=\"1\"",
                "hasAudio=\"1\"",
                "format=\"r1\""
            ]
            if let sanitizedSource {
                assetAttributes.append("src=\"\(sanitizedSource.xmlEscaped())\"")
            }
            let assetLine = "    <asset \(assetAttributes.joined(separator: " "))/>"
            resourceEntries.append(assetLine)

            var clipXML = "      <asset-clip name=\"\(clipName.xmlEscaped())\" ref=\"\(assetID)\" offset=\"\(clipOffset)\" start=\"\(clipStart)\" duration=\"\(clipDuration)\">"

            if configuration.includeMarkers {
                let markers = segment.events
                    .sorted(by: { $0.timestamp < $1.timestamp })
                    .compactMap { event -> String? in
                        guard let label = event.label, !label.isEmpty else { return nil }
                        let relative = event.timestamp.timeIntervalSince(segment.start)
                        return "        <marker start=\"\(timecodeString(for: relative))\" value=\"\(label.xmlEscaped())\"/>"
                    }
                if !markers.isEmpty {
                    clipXML.append("\n")
                    clipXML.append(markers.joined(separator: "\n"))
                    clipXML.append("\n      ")
                }
            }

            clipXML.append("</asset-clip>")
            spineEntries.append(clipXML)
        }

        let xml = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<!DOCTYPE fcpxml>",
            "<fcpxml version=\"1.8\">",
            "  <resources>",
            resourceEntries.joined(separator: "\n"),
            "  </resources>",
            "  <library name=\"\(configuration.libraryName.xmlEscaped())\">",
            "    <event name=\"\(configuration.eventName.xmlEscaped())\">",
            "      <project name=\"\(configuration.projectName.xmlEscaped())\">",
            "        <sequence duration=\"\(sequenceDuration)\" format=\"r1\" tcStart=\"0s\" tcFormat=\"NDF\">",
            "          <spine>",
            spineEntries.joined(separator: "\n"),
            "          </spine>",
            "        </sequence>",
            "      </project>",
            "    </event>",
            "  </library>",
            "</fcpxml>"
        ].joined(separator: "\n")

        logger.info("✅ FCPXML export completed")
        return Data(xml.utf8)
    }
}

private extension FCPXMLExporter {
    func timecodeString(for interval: TimeInterval) -> String {
        guard interval > 0 else { return "0s" }
        let frameDuration = configuration.frameDuration
        let frames = (interval / frameDuration).rounded()
        let frameRate = Double(configuration.frameRate)
        let numerator = max(0, Int(frames))
        if numerator == 0 { return "0s" }
        return "\(numerator)/\(Int(frameRate))s"
    }
}

private extension String {
    func xmlEscaped() -> String {
        var result = self
        let entities: [String: String] = [
            "&": "&amp;",
            "\"": "&quot;",
            "'": "&apos;",
            "<": "&lt;",
            ">": "&gt;"
        ]
        for (character, escape) in entities {
            result = result.replacingOccurrences(of: character, with: escape)
        }
        return result
    }
}
