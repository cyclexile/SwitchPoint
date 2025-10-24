// MARK: - SwitchPointApp.swift
// Entry point for the SwitchPoint SwiftUI application
// Author: Codex Agent

import Foundation
import SwitchPointCore

#if canImport(SwiftUI)
import SwiftUI

@main
struct SwitchPointApp: App {
    @StateObject private var viewModel = TimelineViewModel()

    var body: some Scene {
        WindowGroup {
            TimelineView()
                .environmentObject(viewModel)
        }
    }
}
#else

@main
struct SwitchPointApp {
    static func main() {
        print("SwiftUI is unavailable on this platform. SwitchPointApp cannot launch.")
    }
}

#endif
