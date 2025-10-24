// MARK: - AudioSyncAnalyzer.swift
// Extracts sync peaks from audio waveforms for alignment
// Author: Codex Agent

import Foundation

#if canImport(AVFoundation)
import AVFoundation

/// Identifies significant transient peaks from audio waveforms to serve as sync references.
public struct AudioSyncAnalyzer: Sendable {
    private let logger = Logger(label: "AudioSync")

    public init() {}

    /// Analyzes the waveform within the provided audio file and extracts peak-based events.
    /// - Parameters:
    ///   - url: Location of the audio file (.wav recommended).
    ///   - threshold: Normalized amplitude threshold (0...1) to consider as peaks.
    ///   - minimumSeparation: Minimum time in seconds between detected peaks to avoid duplicates.
    /// - Returns: Array of detected synchronization events.
    public func analyze(url: URL, threshold: Float = 0.6, minimumSeparation: TimeInterval = 1.0) throws -> [SyncEvent] {
        let audioFile = try AVAudioFile(forReading: url)
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount, interleaved: false) else {
            return []
        }

        let frameCount = UInt32(audioFile.length)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        try audioFile.read(into: buffer)

        guard let channelData = buffer.floatChannelData else { return [] }
        let channelCount = Int(buffer.format.channelCount)
        let sampleRate = buffer.format.sampleRate

        var peaks: [SyncEvent] = []
        var lastPeakTime: TimeInterval = -Double.greatestFiniteMagnitude

        for frame in 0..<Int(buffer.frameLength) {
            var aggregated: Float = 0
            for channel in 0..<channelCount {
                aggregated += abs(channelData[channel][frame])
            }
            let normalized = aggregated / Float(channelCount)
            if normalized >= threshold {
                let time = Double(frame) / sampleRate
                if time - lastPeakTime >= minimumSeparation {
                    let timestamp = Date(timeIntervalSince1970: time)
                    peaks.append(SyncEvent(timestamp: timestamp, label: "Audio Peak", sourceFile: url))
                    lastPeakTime = time
                }
            }
        }

        logger.info("Audio peaks detected", metadata: ["count": "\(peaks.count)", "file": url.lastPathComponent])
        return peaks
    }
}
#else

/// Placeholder implementation for platforms without AVFoundation support.
public struct AudioSyncAnalyzer: Sendable {
    public init() {}
    public func analyze(url: URL, threshold: Float = 0.6, minimumSeparation: TimeInterval = 1.0) throws -> [SyncEvent] {
        throw NSError(domain: "AudioSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVFoundation unavailable on this platform."])
    }
}

#endif
