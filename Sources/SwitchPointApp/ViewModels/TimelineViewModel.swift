// MARK: - TimelineViewModel.swift
// Observable interface bridging core timeline synchronization to SwiftUI views
// Author: Codex Agent

#if canImport(SwiftUI)
import Foundation
import Combine
import SwitchPointCore

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published private(set) var timeline: Timeline = Timeline()
    @Published var error: String?

    private var cancellables: Set<AnyCancellable> = []
    private let synchronizer: TimelineSynchronizer
    private let manualSyncTool = ManualSyncTool()

    init() {
        let referenceID = UUID()
        let referenceDevice = Device(id: referenceID, name: "Reference Camera", type: .camera, events: [])
        self.devices = [referenceDevice]
        self.synchronizer = TimelineSynchronizer(configuration: .init(referenceDeviceID: referenceID))
    }

    func addDevice(_ device: Device) {
        devices.append(device)
        devices.sort { $0.name < $1.name }
        recomputeTimeline()
    }

    func updateManualSync(timestamp: Date, label: String?) {
        Task {
            await manualSyncTool.addEvent(at: timestamp, label: label)
            let manualEvents = await manualSyncTool.allEvents()
            await MainActor.run {
                if let index = devices.firstIndex(where: { $0.type == .manual }) {
                    var updated = devices[index]
                    updated.events = manualEvents
                    devices[index] = updated
                } else {
                    let manualDevice = Device(name: "Manual", type: .manual, events: manualEvents)
                    devices.append(manualDevice)
                }
                recomputeTimeline()
            }
        }
    }

    func recomputeTimeline() {
        do {
            timeline = try synchronizer.synchronize(devices: devices)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
#endif
