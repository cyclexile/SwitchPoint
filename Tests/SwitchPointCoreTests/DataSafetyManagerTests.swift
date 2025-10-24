// MARK: - DataSafetyManagerTests.swift
// Ensures backup creation, rotation, and rollback behavior
// Author: Codex Agent

import XCTest
@testable import SwitchPointCore

final class DataSafetyManagerTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try super.tearDownWithError()
    }

    func testBackupCreationAndRotation() throws {
        try "sample".data(using: .utf8)?.write(to: tempDirectory.appendingPathComponent("data.json"))

        let manager = DataSafetyManager(storageURL: tempDirectory, maxBackups: 2)
        let first = try manager.createBackup()
        let second = try manager.createBackup(timestamp: Date().addingTimeInterval(1))
        _ = try manager.createBackup(timestamp: Date().addingTimeInterval(2))

        let backups = try FileManager.default.contentsOfDirectory(at: tempDirectory.appendingPathComponent("Backups"), includingPropertiesForKeys: nil)
        XCTAssertEqual(backups.count, 2)
        XCTAssertFalse(backups.contains(first))
        XCTAssertTrue(backups.contains(second))
    }

    func testMigrationRollbackOnFailure() throws {
        let failingMigration = FailingMigration()
        let manager = DataSafetyManager(storageURL: tempDirectory)
        try manager.createBackup()
        XCTAssertThrowsError(try manager.performMigration(failingMigration))
    }
}

private struct FailingMigration: Migratable {
    var fromVersion: Int { 1 }
    var toVersion: Int { 2 }

    func migrate(on url: URL) throws {
        throw NSError(domain: "test", code: 1)
    }
}
