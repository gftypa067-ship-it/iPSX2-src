// SettingsStore.swift — INI-backed settings for SwiftUI
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI
import Combine

/// [P51] OSD preset levels
enum OsdPreset: Int, CaseIterable {
    case off = 0
    case simple = 1    // FPS + CPU usage
    case detail = 2    // All except frame times graph
    case full = 3      // Everything

    var label: String {
        switch self {
        case .off: return "OFF"
        case .simple: return "Simple"
        case .detail: return "Detail"
        case .full: return "Full"
        }
    }
}

final class SettingsStore: ObservableObject, @unchecked Sendable {
    static let shared = SettingsStore()

    // ── Emulator / CPU ──
    @Published var eeCoreType: Int {
        didSet { saveAndNotify() }
    }
    @Published var iopRecompiler: Bool {
        didSet { saveAndNotify() }
    }
    @Published var vu0Recompiler: Bool {
        didSet { saveAndNotify() }
    }
    @Published var vu1Recompiler: Bool {
        didSet { saveAndNotify() }
    }
    @Published var fastBoot: Bool {
        didSet { saveAndNotify() }
    }
    @Published var fastmem: Bool {
        didSet { saveAndNotify() }
    }

    // ── Boot ──
    @Published var fastCDVD: Bool {
        didSet { saveAndNotify() }
    }

    // ── Advanced Speedhacks ──
    @Published var eeCycleRate: Int {
        didSet { saveAndNotify() }
    }
    @Published var vu1Instant: Bool {
        didSet { saveAndNotify() }
    }
    @Published var waitLoop: Bool {
        didSet { saveAndNotify() }
    }
    @Published var intcStat: Bool {
        didSet { saveAndNotify() }
    }

    // ── Graphics ──
    @Published var renderer: Int {
        didSet { saveAndNotify() }
    }
    @Published var upscaleMultiplier: Float {
        didSet { saveAndNotify() }
    }
    @Published var vsyncQueueSize: Int {
        didSet { saveAndNotify() }
    }
    @Published var textureFiltering: Int {
        didSet { saveAndNotify() }
    }
    @Published var fxaa: Bool {
        didSet { saveAndNotify() }
    }
    @Published var casMode: Int {
        didSet { saveAndNotify() }
    }
    @Published var casSharpness: Int {
        didSet { saveAndNotify() }
    }
    @Published var interlaceMode: Int {
        didSet { saveAndNotify() }
    }
    @Published var aspectRatio: Int {
        didSet { saveAndNotify() }
    }
    @Published var blendingAccuracy: Int {
        didSet { saveAndNotify() }
    }
    @Published var dithering: Int {
        didSet { saveAndNotify() }
    }

    // ── OSD Overlay ──
    @Published var osdPreset: OsdPreset {
        didSet {
            applyOsdPreset(osdPreset)
            saveAndNotify()
        }
    }
    @Published var osdShowFPS: Bool {
        didSet { saveAndNotify() }
    }
    @Published var osdShowSpeed: Bool {
        didSet { saveAndNotify() }
    }
    @Published var osdShowCPU: Bool {
        didSet { saveAndNotify() }
    }
    @Published var osdShowResolution: Bool {
        didSet { saveAndNotify() }
    }
    @Published var osdShowFrameTimes: Bool {
        didSet { saveAndNotify() }
    }

    // ── Gamepad / UI ──
    @Published var padOpacity: Float {
        didSet { saveAndNotify() }
    }
    @Published var hapticFeedback: Bool {
        didSet { saveAndNotify() }
    }

    // ── Init from INI ──
    private init() {
        // CPU
        eeCoreType = Int(iPSX2Bridge.getINIInt("EmuCore/CPU", key: "CoreType", defaultValue: 0))
        iopRecompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableIOP", defaultValue: true)
        vu0Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU0", defaultValue: true)
        vu1Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU1", defaultValue: true)
        fastBoot = iPSX2Bridge.getINIBool("GameISO", key: "FastBoot", defaultValue: false)
        fastmem = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableFastmem", defaultValue: true)
        // Boot
        fastCDVD = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "fastCDVD", defaultValue: false)
        // Advanced Speedhacks
        eeCycleRate = Int(iPSX2Bridge.getINIInt("EmuCore/Speedhacks", key: "EECycleRate", defaultValue: 0))
        vu1Instant = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "vu1Instant", defaultValue: true)
        waitLoop = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "WaitLoop", defaultValue: true)
        intcStat = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "IntcStat", defaultValue: true)
        // Graphics
        renderer = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "Renderer", defaultValue: 17))
        upscaleMultiplier = iPSX2Bridge.getINIFloat("EmuCore/GS", key: "upscale_multiplier", defaultValue: 1.0)
        vsyncQueueSize = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "VsyncQueueSize", defaultValue: 8))
        textureFiltering = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "filter", defaultValue: 2))
        fxaa = iPSX2Bridge.getINIBool("EmuCore/GS", key: "fxaa", defaultValue: false)
        casMode = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "CASMode", defaultValue: 0))
        casSharpness = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "CASSharpness", defaultValue: 50))
        interlaceMode = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "deinterlace_mode", defaultValue: 7))
        aspectRatio = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "AspectRatio", defaultValue: 0))
        blendingAccuracy = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "accurate_blending_unit", defaultValue: 1))
        dithering = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "dithering_ps2", defaultValue: 2))
        // OSD
        osdPreset = OsdPreset(rawValue: Int(iPSX2Bridge.getINIInt("iPSX2/UI", key: "OsdPreset", defaultValue: 0))) ?? .off
        osdShowFPS = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFPS", defaultValue: false)
        osdShowSpeed = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowSpeed", defaultValue: false)
        osdShowCPU = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowCPU", defaultValue: false)
        osdShowResolution = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowResolution", defaultValue: false)
        osdShowFrameTimes = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFrameTimes", defaultValue: false)
        // UI
        padOpacity = iPSX2Bridge.getINIFloat("iPSX2/UI", key: "PadOpacity", defaultValue: 0.6)
        hapticFeedback = iPSX2Bridge.getINIBool("iPSX2/UI", key: "HapticFeedback", defaultValue: true)
        // [P60] Force MTVU off (known buggy)
        iPSX2Bridge.setINIBool("EmuCore/Speedhacks", key: "vuThread", value: false)
        // Apply OSD preset
        iPSX2Bridge.applyOsdPreset(Int32(clamping:osdPreset.rawValue))
    }

    /// Reload ALL settings from INI (call on VM start/stop)
    func reload() {
        eeCoreType = Int(iPSX2Bridge.getINIInt("EmuCore/CPU", key: "CoreType", defaultValue: 0))
        iopRecompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableIOP", defaultValue: true)
        vu0Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU0", defaultValue: true)
        vu1Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU1", defaultValue: true)
        fastBoot = iPSX2Bridge.getINIBool("GameISO", key: "FastBoot", defaultValue: false)
        fastmem = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableFastmem", defaultValue: true)
        fastCDVD = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "fastCDVD", defaultValue: false)
        eeCycleRate = Int(iPSX2Bridge.getINIInt("EmuCore/Speedhacks", key: "EECycleRate", defaultValue: 0))
        vu1Instant = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "vu1Instant", defaultValue: true)
        waitLoop = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "WaitLoop", defaultValue: true)
        intcStat = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "IntcStat", defaultValue: true)
        renderer = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "Renderer", defaultValue: 17))
        upscaleMultiplier = iPSX2Bridge.getINIFloat("EmuCore/GS", key: "upscale_multiplier", defaultValue: 1.0)
        vsyncQueueSize = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "VsyncQueueSize", defaultValue: 8))
        textureFiltering = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "filter", defaultValue: 2))
        fxaa = iPSX2Bridge.getINIBool("EmuCore/GS", key: "fxaa", defaultValue: false)
        casMode = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "CASMode", defaultValue: 0))
        casSharpness = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "CASSharpness", defaultValue: 50))
        interlaceMode = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "deinterlace_mode", defaultValue: 7))
        aspectRatio = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "AspectRatio", defaultValue: 0))
        blendingAccuracy = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "accurate_blending_unit", defaultValue: 1))
        dithering = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "dithering_ps2", defaultValue: 2))
        osdPreset = OsdPreset(rawValue: Int(iPSX2Bridge.getINIInt("iPSX2/UI", key: "OsdPreset", defaultValue: 0))) ?? .off
        osdShowFPS = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFPS", defaultValue: false)
        osdShowSpeed = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowSpeed", defaultValue: false)
        osdShowCPU = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowCPU", defaultValue: false)
        osdShowResolution = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowResolution", defaultValue: false)
        osdShowFrameTimes = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFrameTimes", defaultValue: false)
        padOpacity = iPSX2Bridge.getINIFloat("iPSX2/UI", key: "PadOpacity", defaultValue: 0.6)
        hapticFeedback = iPSX2Bridge.getINIBool("iPSX2/UI", key: "HapticFeedback", defaultValue: true)
    }

    /// Apply OSD preset — writes ALL OSD flags to INI + GSConfig
    private func applyOsdPreset(_ preset: OsdPreset) {
        iPSX2Bridge.applyOsdPreset(Int32(clamping:preset.rawValue))
        let isSimple = preset == .simple
        let isDetail = preset == .detail
        let isFull = preset == .full
        osdShowFPS = isSimple || isDetail || isFull
        osdShowSpeed = isDetail || isFull
        osdShowCPU = isSimple || isDetail || isFull
        osdShowResolution = isDetail || isFull
        osdShowFrameTimes = isFull
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowVPS", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowVersion", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowHardwareInfo", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowGPU", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowGSStats", value: false)
    }

    /// Reset emulator settings to PC PCSX2 defaults
    func resetEmulatorDefaults() {
        eeCoreType = 0          // JIT
        iopRecompiler = true
        vu0Recompiler = true    // PC PCSX2 default: microVU JIT
        vu1Recompiler = true    // PC PCSX2 default: microVU JIT
        fastBoot = false
        fastmem = true
        fastCDVD = false
        eeCycleRate = 0
        vu1Instant = true       // PC PCSX2 recommended default
        waitLoop = true         // PC PCSX2 recommended default
        intcStat = true         // PC PCSX2 recommended default
        saveAndNotify()
    }

    /// Reset graphics settings to PC PCSX2 defaults
    func resetGraphicsDefaults() {
        renderer = 17           // Metal
        upscaleMultiplier = 1.0 // Native PS2
        vsyncQueueSize = 8
        textureFiltering = 2    // Bilinear (PS2)
        fxaa = false
        casMode = 0             // Disabled
        casSharpness = 50
        interlaceMode = 7       // Adaptive
        aspectRatio = 0         // Auto 4:3/3:2
        blendingAccuracy = 1    // Basic
        dithering = 2           // Scaled
        saveAndNotify()
    }

    // ================================================================
    // ✅ دالة مساعدة للحفظ والإشعار
    // ================================================================
    private func saveAndNotify() {
        // إجبار الواجهة على التحديث (للتأكد من أن SwiftUI يعرف بالتغيير)
        objectWillChange.send()
        // حفظ الـ INI (إذا كانت هناك دوال حفظ عامة)
        // ملاحظة: دوال setINIInt تقوم بالحفظ تلقائياً، لكن نضيف هذا للتأكد
        iPSX2Bridge.saveSettings?() // إذا كانت موجودة، وإلا تجاهل
    }
}
