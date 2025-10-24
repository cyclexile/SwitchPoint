// MARK: - Logging.swift
// Lightweight logging helper tailored for synchronization workflows
// Author: Codex Agent

import Foundation

public protocol LogDestination: Sendable {
    func log(level: Logger.Level, message: String, metadata: [String: String]?)
}

public struct Logger: Sendable {
    public enum Level: String, Sendable {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
    }

    private let label: String
    private let destination: LogDestination

    public init(label: String, destination: LogDestination = ConsoleDestination()) {
        self.label = label
        self.destination = destination
    }

    public func debug(_ message: String, metadata: [String: String]? = nil) {
        destination.log(level: .debug, message: formatted(message), metadata: metadata)
    }

    public func info(_ message: String, metadata: [String: String]? = nil) {
        destination.log(level: .info, message: formatted(message), metadata: metadata)
    }

    public func warning(_ message: String, metadata: [String: String]? = nil) {
        destination.log(level: .warning, message: formatted(message), metadata: metadata)
    }

    public func error(_ message: String, metadata: [String: String]? = nil) {
        destination.log(level: .error, message: formatted(message), metadata: metadata)
    }

    private func formatted(_ message: String) -> String {
        "[\(label)] \(message)"
    }
}

public struct ConsoleDestination: LogDestination {
    private let queue = DispatchQueue(label: "com.switchpoint.logger", qos: .utility)

    public init() {}

    public func log(level: Logger.Level, message: String, metadata: [String : String]?) {
        queue.async {
            let metadataText = metadata?.map { "\($0.key)=\($0.value)" }.joined(separator: " ") ?? ""
            print("\(level.rawValue) \(message) \(metadataText)")
        }
    }
}
