// MARK: - ATEMParser.swift
// Parses ATEM switcher log CSV/XML into SyncEvents
// Author: Codex Agent

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Handles parsing of ATEM switcher export files to synchronization events.
public struct ATEMParser: Sendable {
    private let queue = DispatchQueue(label: "com.switchpoint.atemparser", qos: .userInitiated)

    public init() {}

    /// Parses an ATEM switcher log file at the provided URL.
    /// - Parameter url: File URL pointing to a CSV or XML export.
    /// - Returns: Ordered synchronization events.
    public func parse(url: URL) throws -> [SyncEvent] {
        let data = try Data(contentsOf: url)
        if url.pathExtension.lowercased() == "csv" {
            return try parseCSV(data: data)
        } else if url.pathExtension.lowercased() == "xml" {
            return try parseXML(data: data)
        } else {
            throw ParserError.unsupportedFormat(url.pathExtension)
        }
    }

    /// Parses ATEM log content from raw string.
    public func parse(string: String, format: FileFormat) throws -> [SyncEvent] {
        let data = Data(string.utf8)
        switch format {
        case .csv: return try parseCSV(data: data)
        case .xml: return try parseXML(data: data)
        }
    }
}

public extension ATEMParser {
    enum ParserError: Error, LocalizedError {
        case unsupportedFormat(String)
        case invalidStructure
        case xmlParsingFailed(String)
        case csvParsingFailed(String)

        public var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let ext):
                return "Unsupported ATEM log format: \(ext)"
            case .invalidStructure:
                return "ATEM log structure is invalid or missing required columns."
            case .xmlParsingFailed(let reason):
                return "Failed to parse ATEM XML: \(reason)"
            case .csvParsingFailed(let reason):
                return "Failed to parse ATEM CSV: \(reason)"
            }
        }
    }

    enum FileFormat {
        case csv
        case xml
    }
}

private extension ATEMParser {
    func parseCSV(data: Data) throws -> [SyncEvent] {
        try queue.sync {
            guard let content = String(data: data, encoding: .utf8) else {
                throw ParserError.csvParsingFailed("File is not valid UTF-8")
            }
            let rows = content
                .split(whereSeparator: { $0.isNewline })
                .map(String.init)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            guard let header = rows.first else {
                throw ParserError.invalidStructure
            }
            let columns = header.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let timeIndex = columns.firstIndex(where: { $0.lowercased().contains("time") }),
                  let labelIndex = columns.firstIndex(where: { $0.lowercased().contains("source") || $0.lowercased().contains("input") }) else {
                throw ParserError.invalidStructure
            }

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let events = try rows.dropFirst().compactMap { row -> SyncEvent? in
                let values = row.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                guard values.indices.contains(timeIndex), values.indices.contains(labelIndex) else {
                    throw ParserError.invalidStructure
                }
                let rawDate = values[timeIndex]
                guard let timestamp = dateFormatter.date(from: rawDate) ?? DateFormatter.cachedDateFormatter.date(from: rawDate) else {
                    throw ParserError.csvParsingFailed("Unrecognized timestamp: \(rawDate)")
                }
                let label = values[labelIndex]
                return SyncEvent(timestamp: timestamp, label: label.isEmpty ? nil : label)
            }
            return events.ordered()
        }
    }

    func parseXML(data: Data) throws -> [SyncEvent] {
        #if canImport(FoundationXML)
        return try queue.sync {
            let parserDelegate = ATEMXMLParserDelegate()
            let parser = XMLParser(data: data)
            parser.delegate = parserDelegate
            guard parser.parse() else {
                throw ParserError.xmlParsingFailed(parser.parserError?.localizedDescription ?? "Unknown error")
            }
            return parserDelegate.events.ordered()
        }
        #else
        throw ParserError.xmlParsingFailed("XML parsing not supported on this platform")
        #endif
    }
}

#if canImport(FoundationXML)
private final class ATEMXMLParserDelegate: NSObject, XMLParserDelegate {
    private(set) var events: [SyncEvent] = []
    private var currentTimestamp: Date?
    private var currentLabel: String?
    private var buffer: String = ""

    private lazy var isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName.lowercased().contains("event") {
            currentTimestamp = nil
            currentLabel = nil
        }
        buffer.removeAll()
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer.append(string)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if elementName.lowercased().contains("time") {
            currentTimestamp = isoFormatter.date(from: value) ?? DateFormatter.cachedDateFormatter.date(from: value)
        } else if elementName.lowercased().contains("source") || elementName.lowercased().contains("input") {
            currentLabel = value
        } else if elementName.lowercased().contains("event") {
            guard let timestamp = currentTimestamp else { return }
            let event = SyncEvent(timestamp: timestamp, label: currentLabel?.isEmpty == true ? nil : currentLabel)
            events.append(event)
        }
        buffer.removeAll()
    }
}
#endif
