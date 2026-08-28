// AppState.swift — App screen state management
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI
import Combine

final class AppState: ObservableObject, @unchecked Sendable {
    static let shared = AppState()

    enum Screen {
        case menu
        case playing
    }

    @Published var currentScreen: Screen = .menu
    @Published var selectedTab: Int = 0
    @Published var runningGameName: String? = nil
    @Published var hideStatusBar: Bool = false

    private var pendingBootAction: (() -> Void)?
    private var shutdownObserver: NSObjectProtocol?
    private var autoBootObserver: NSObjectProtocol?

    private init() {
        shutdownObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("iPSX2VMDidShutdown"),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.runningGameName = nil
            if let action = self?.pendingBootAction {
                self?.pendingBootAction = nil
                action()
            } else {
                // ✅ العودة إلى القائمة بعد إيقاف VM
                self?.currentScreen = .menu
            }
        }

        autoBootObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("iPSX2AutoBootDidStart"),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.runningGameName = "AutoBoot"
            self?.currentScreen = .playing
        }
    }

    func bootGame(isoName: String) {
        iPSX2Bridge.bootISO(isoName)
        iPSX2Bridge.requestVMBoot()
        runningGameName = isoName
        currentScreen = .playing
    }

    func bootBIOSOnly() {
        iPSX2Bridge.setINIString("GameISO", key: "BootISO", value: "")
        iPSX2Bridge.requestVMBoot()
        runningGameName = "BIOS"
        currentScreen = .playing
    }

    // ✅ إصلاح شامل لدالة العودة إلى القائمة
    func returnToMenu() {
        // 1. تغيير الحالة فوراً
        currentScreen = .menu
        runningGameName = nil
        
        // 2. إذا كان VM يعمل، أطلب إيقافه
        if iPSX2Bridge.isVMRunning() {
            iPSX2Bridge.requestVMShutdown()
        }
        
        // 3. إشعار لـ ObjC side (اختياري)
        NotificationCenter.default.post(name: NSNotification.Name("iPSX2ReturnToMenu"), object: nil)
    }

    func returnToGame() {
        if runningGameName != nil {
            NotificationCenter.default.post(name: NSNotification.Name("iPSX2EnterGameScreen"), object: nil)
            currentScreen = .playing
        }
    }

    func shutdownAndBoot(isoName: String) {
        pendingBootAction = { [weak self] in
            self?.bootGame(isoName: isoName)
        }
        iPSX2Bridge.requestVMShutdown()
    }

    func shutdownAndBootBIOS() {
        pendingBootAction = { [weak self] in
            self?.bootBIOSOnly()
        }
        iPSX2Bridge.requestVMShutdown()
    }

    deinit {
        if let obs = shutdownObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = autoBootObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
