// EmulatorBridge.swift — SwiftUI ↔ C++ emulator bridge
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI
import Combine

enum EmulatorState: String {
    case stopped = "Stopped"
    case running = "Running"
    case paused = "Paused"
    case saving = "Saving"
    case suspended = "Suspended"
}

final class EmulatorBridge: ObservableObject, @unchecked Sendable {
    static let shared = EmulatorBridge()

    @Published var state: EmulatorState = .stopped
    @Published var lastSaveDate: Date? = nil
    @Published var lastSaveSuccess: Bool = true
    @Published var biosName: String = "Unknown"
    @Published var buildVersion: String = ""

    private init() {
        biosName = iPSX2Bridge.biosName()
        buildVersion = iPSX2Bridge.buildVersion()
    }

    func saveAll() {
        state = .saving
        iPSX2Bridge.saveAllState()
        lastSaveDate = Date()
        lastSaveSuccess = true
        state = .running
    }

    func setPadButton(_ button: iPSX2PadButton, pressed: Bool) {
        iPSX2Bridge.setPadButton(button, pressed: pressed)
    }

    func setLeftStick(x: Float, y: Float) {
        iPSX2Bridge.setLeftStickX(x, y: y)
    }

    func setRightStick(x: Float, y: Float) {
        iPSX2Bridge.setRightStickX(x, y: y)
    }

    var isOsdVisible: Bool {
        get { iPSX2Bridge.isPerformanceOverlayVisible() }
        set { iPSX2Bridge.setPerformanceOverlayVisible(newValue) }
    }
}
