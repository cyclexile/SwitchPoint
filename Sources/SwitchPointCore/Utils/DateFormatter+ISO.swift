// MARK: - DateFormatter+ISO.swift
// Provides reusable ISO8601 and fallback date formatter utilities
// Author: Codex Agent

import Foundation

public extension DateFormatter {
    /// Shared fallback formatter for ATEM or metadata timestamps using common patterns.
    static let cachedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

public extension ISO8601DateFormatter {
    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
