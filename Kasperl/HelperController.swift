//
//  HelperController.swift
//  Kasperl
//
//  Created by Matthias Keiser on 06/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import AppKit
import ServiceManagement

/// Encapsulates various functionality to control the helper tool.
class HelperController {

    func start() {
        HelperController.setHelperAppRunning(true)
    }

    func stop() {
        if !UserDefaults.standard.startAtLogin {
            HelperController.setHelperAppRunning(false)
        }
    }

    private static func setHelperAppRunning(_ shouldRun: Bool) {
        guard SMLoginItemSetEnabled("com.TristanInc.Kasperl-Helper" as CFString, shouldRun) == true else {
            let error = shouldRun ? HelperControllerError.failedToLaunchHelperTool : HelperControllerError.failedToQuitHelperTool
            NSApplication.shared.presentError(error)
            return
        }
    }

    enum HelperControllerError: Error {
        case failedToLaunchHelperTool
        case failedToQuitHelperTool
    }
}

extension UserDefaults {
    /// A KVO-compatible extension to get the startAtLogin user default setting.
    @objc public var startAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "startAtLogin")}
        set { UserDefaults.standard.set(newValue, forKey: "startAtLogin")}
    }
}

