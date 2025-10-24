// MARK: - TimelineView.swift
// Presents a visual overview of the synchronized timeline
// Author: Codex Agent

#if canImport(SwiftUI)
import SwiftUI
import SwitchPointCore

struct TimelineView: View {
    @EnvironmentObject private var viewModel: TimelineViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                }
                DeviceListView(devices: viewModel.devices)
                Divider()
                TimelineCanvas(timeline: viewModel.timeline)
            }
            .padding()
            .navigationTitle("SwitchPoint Timeline")
        }
    }
}

private struct DeviceListView: View {
    let devices: [Device]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Devices")
                .font(.headline)
            ForEach(devices) { device in
                HStack {
                    Text(device.name)
                        .font(.subheadline)
                    Spacer()
                    Text(device.type.rawValue.capitalized)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct TimelineCanvas: View {
    let timeline: Timeline

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline Segments")
                .font(.headline)
            if timeline.segments.isEmpty {
                Text("No segments available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(timeline.segments) { segment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device: \(segment.deviceID.uuidString.prefix(6)) | Offset: \(segment.offset, specifier: "%.3f")s")
                            .font(.subheadline)
                        ForEach(segment.events) { event in
                            Text("• \(event.timestamp.ISO8601Format()) \(event.label ?? "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
            }
        }
    }
}

#Preview {
    TimelineView()
        .environmentObject(TimelineViewModel())
}
#endif
