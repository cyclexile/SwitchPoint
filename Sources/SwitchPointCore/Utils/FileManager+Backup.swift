// MARK: - FileManager+Backup.swift
// Utilities for consistent backup directory management
// Author: Codex Agent

import Foundation

public extension FileManager {
    /// Returns the URL for the application's backup directory, creating it if necessary.
    func ensureBackupDirectory(for baseURL: URL) throws -> URL {
        let backupURL = baseURL.appendingPathComponent("Backups", isDirectory: true)
        if !fileExists(atPath: backupURL.path) {
            try createDirectory(at: backupURL, withIntermediateDirectories: true)
        }
        return backupURL
    }

    /// Generates a timestamped backup folder URL.
    func backupFolderURL(baseURL: URL, timestamp: Date = .now) -> URL {
        let formatter = ISO8601DateFormatter.fractional
        let folderName = formatter.string(from: timestamp)
        return baseURL.appendingPathComponent(folderName, isDirectory: true)
    }
}
