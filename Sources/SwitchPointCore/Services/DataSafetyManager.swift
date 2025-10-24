// MARK: - DataSafetyManager.swift
// Manages backups, migrations, and recovery for local persistence
// Author: Codex Agent

import Foundation

/// Defines a versioned migration task.
public protocol Migratable: Sendable {
    var fromVersion: Int { get }
    var toVersion: Int { get }
    func migrate(on url: URL) throws
}

/// Coordinates backup rotation, migrations, and rollback handling.
public final class DataSafetyManager: @unchecked Sendable {
    private let fileManager: FileManager
    private let logger: Logger
    private let queue = DispatchQueue(label: "com.switchpoint.datasafety", qos: .userInitiated)
    private let storageURL: URL
    private let maxBackups: Int

    public init(
        storageURL: URL,
        fileManager: FileManager = .default,
        logger: Logger = Logger(label: "DataSafety"),
        maxBackups: Int = 5
    ) {
        self.storageURL = storageURL
        self.fileManager = fileManager
        self.logger = logger
        self.maxBackups = maxBackups
    }

    /// Executes a migration while protecting existing data through versioned backups.
    public func performMigration(_ migration: Migratable) throws {
        try queue.sync {
            logger.info("📍 Migration started", metadata: ["from": "\(migration.fromVersion)", "to": "\(migration.toVersion)"])
            let backupURL = try createBackupLocked()
            do {
                try migration.migrate(on: storageURL)
                try rotateBackupsLocked()
                logger.info("✅ Migration completed")
            } catch {
                logger.error("Migration failed, starting rollback", metadata: ["error": "\(error.localizedDescription)"])
                try restoreBackupLocked(from: backupURL)
                throw error
            }
        }
    }

    /// Creates a snapshot of the storage directory for recovery purposes.
    @discardableResult
    public func createBackup(timestamp: Date = .now) throws -> URL {
        try queue.sync {
            try createBackupLocked(timestamp: timestamp)
        }
    }

    /// Restores the storage directory from a specific backup.
    public func restoreBackup(from backupURL: URL) throws {
        try queue.sync {
            try restoreBackupLocked(from: backupURL)
        }
    }
}

private extension DataSafetyManager {
    func createBackupLocked(timestamp: Date = .now) throws -> URL {
        let backupDirectory = try fileManager.ensureBackupDirectory(for: storageURL)
        let target = fileManager.backupFolderURL(baseURL: backupDirectory, timestamp: timestamp)
        try fileManager.createDirectory(at: target, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: storageURL.path) {
            let contents = try fileManager.contentsOfDirectory(atPath: storageURL.path)
            for item in contents {
                guard item != "Backups" else { continue }
                let source = storageURL.appendingPathComponent(item)
                let destination = target.appendingPathComponent(item)
                try fileManager.copyItem(at: source, to: destination)
            }
        }
        logger.info("💾 Backup created", metadata: ["path": target.path])
        try rotateBackupsLocked()
        return target
    }

    func restoreBackupLocked(from backupURL: URL) throws {
        if fileManager.fileExists(atPath: storageURL.path) {
            try fileManager.removeItem(at: storageURL)
        }
        try fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
        let contents = try fileManager.contentsOfDirectory(atPath: backupURL.path)
        for item in contents {
            let source = backupURL.appendingPathComponent(item)
            let destination = storageURL.appendingPathComponent(item)
            try fileManager.copyItem(at: source, to: destination)
        }
        logger.info("♻️ Backup restored", metadata: ["path": backupURL.path])
    }

    func rotateBackupsLocked() throws {
        let backupDirectory = try fileManager.ensureBackupDirectory(for: storageURL)
        let backups = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        if backups.count > maxBackups {
            let toRemove = backups.suffix(from: maxBackups)
            for url in toRemove {
                try fileManager.removeItem(at: url)
                logger.info("🧹 Old backup pruned", metadata: ["path": url.path])
            }
        }
    }
}
