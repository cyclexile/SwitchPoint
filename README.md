# SwitchPoint

SwitchPoint is a multi-camera editing and timestamp synchronization system designed to align media originating from Blackmagic ATEM switchers, cinema cameras, and field recorders. The project emphasizes data safety, modular parsing, and accurate master timeline generation suitable for editorial export pipelines.

## Package Structure

```
SwitchPoint/
├── Package.swift
├── Sources/
│   ├── SwitchPointCore/         # Core models, services, and utilities
│   └── SwitchPointApp/          # SwiftUI reference application
└── Tests/                       # XCTest coverage for critical modules
```

## Core Capabilities

* **Device & Timeline Models** – Strongly typed models for devices, synchronization events, and master timeline segments.
* **ATEM Log Parsing** – CSV/XML parsers convert switcher logs into chronological sync events.
* **Audio Peak Detection** – Waveform analysis extracts transient peaks suitable for synchronization anchors.
* **Video Metadata Import** – Gathers clip start times and embedded metadata markers.
* **Manual Sync Tooling** – Thread-safe manual marker entry for fine-grained alignment.
* **Timeline Synchronizer** – Reference-aware offset computation producing frame-rounded alignment.
* **Final Cut Pro Export** – Deterministic FCPXML serialization of the synchronized master timeline with optional marker annotations.
* **Data Safety Layer** – Backup, migration, and rollback utilities with automated rotation.
* **SwiftUI Visualization** – Lightweight UI visualizing device status and resulting timeline segments.

## Getting Started

1. Ensure Xcode 15 or Swift 5.9 toolchain is available.
2. Build and run the SwiftUI app:
   ```bash
   swift run SwitchPointApp
   ```
3. Execute unit tests:
   ```bash
   swift test
   ```

## Roadmap

Future milestones include advanced waveform correlation, timeline editing gestures, and export pipelines for DaVinci Resolve XML formats.
