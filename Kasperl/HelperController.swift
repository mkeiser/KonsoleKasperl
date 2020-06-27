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

    func start() throws {
        try HelperController.setHelperAppRunning(true)
    }

    func stop() throws {
        if !UserDefaults.standard.startAtLogin {
            try HelperController.setHelperAppRunning(false)
        }
    }

    private static func setHelperAppRunning(_ shouldRun: Bool) throws {
        guard SMLoginItemSetEnabled("com.TristanInc.Kasperl-Helper" as CFString, shouldRun) == true else {
            throw shouldRun ? HelperControllerError.failedToLaunchHelperTool : HelperControllerError.failedToQuitHelperTool
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

