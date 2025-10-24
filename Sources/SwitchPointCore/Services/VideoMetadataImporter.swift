// MARK: - VideoMetadataImporter.swift
// Imports creation dates and metadata from camera media files
// Author: Codex Agent

import Foundation

#if canImport(AVFoundation)
import AVFoundation

/// Extracts timestamp metadata from video files to generate synchronization events.
public struct VideoMetadataImporter: Sendable {
    private let logger = Logger(label: "VideoMetadata")

    public init() {}

    /// Parses metadata for a given video asset.
    /// - Parameter url: File URL of the video asset (.mov / .mp4).
    /// - Returns: Sync events representing the start of recording and optional additional metadata markers.
    public func importMetadata(from url: URL) throws -> [SyncEvent] {
        let asset = AVURLAsset(url: url)
        let creationDate = try assetCreationDate(asset: asset)
        var events: [SyncEvent] = []
        if let creationDate {
            events.append(SyncEvent(timestamp: creationDate, label: "Clip Start", sourceFile: url))
        }

        let metadataEvents = extractMetadataMarkers(asset: asset, url: url)
        events.append(contentsOf: metadataEvents)
        logger.info("Metadata imported", metadata: ["file": url.lastPathComponent, "events": "\(events.count)"])
        return events.ordered()
    }

    private func assetCreationDate(asset: AVAsset) throws -> Date? {
        if let creationDate = asset.creationDate?.dateValue {
            return creationDate
        }
        let resourceValues = try asset.url.resourceValues(forKeys: [.creationDateKey])
        return resourceValues.creationDate
    }

    private func extractMetadataMarkers(asset: AVAsset, url: URL) -> [SyncEvent] {
        var events: [SyncEvent] = []
        let metadataItems = asset.metadata(forFormat: AVMetadataFormat.quickTimeMetadata)
        for item in metadataItems {
            guard let identifier = item.identifier?.rawValue else { continue }
            if identifier.contains("com.apple.quicktime.location.ISO6709") {
                continue // skip geolocation metadata
            }
            if let time = item.time, time.isValid, time.isNumeric {
                let seconds = time.seconds
                let timestamp = (try? assetCreationDate(asset: asset))?.addingTimeInterval(seconds)
                if let timestamp {
                    events.append(SyncEvent(timestamp: timestamp, label: item.identifier?.rawValue, sourceFile: url))
                }
            }
        }
        return events
    }
}
#else

/// Placeholder implementation for platforms without AVFoundation support.
public struct VideoMetadataImporter: Sendable {
    public init() {}
    public func importMetadata(from url: URL) throws -> [SyncEvent] {
        throw NSError(domain: "VideoMetadata", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVFoundation unavailable on this platform."])
    }
}

#endif
