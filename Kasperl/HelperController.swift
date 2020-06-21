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

    /// If true, the helper app will be run as a login item. If not, the helper will be run like a child process, only while the main app is also running.
    var runAsLoginItem: Bool = false {
        didSet {
            updateRunMode()
        }
    }

    init(runAsLoginItem: Bool) {
        self.runAsLoginItem = runAsLoginItem
    }

    func start() {
        updateRunMode()
    }

    /// If the helper is _not_ running as a login process, this holds manually managed child process instead.
    private var manualHelperProcess: NSRunningApplication? {
        willSet {
            manualHelperProcess?.forceTerminate()
        }
    }


    func stopManualHelperProcess() {
        manualHelperProcess = nil
    }

    func startManualHelperProcess() {
        stopManualHelperProcess()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.addsToRecentItems = false

        NSWorkspace.shared.openApplication(at: HelperController.helperToolURL, configuration: configuration) { app, error in

            DispatchQueue.main.async {
                guard let app = app else {
                    self.presentError(error ?? HelperControllerError.failedToLaunchHelperTool)
                    return
                }
                self.manualHelperProcess = app
            }
        }
    }

    /// Updates the child process according to the current "run mode" setting:
    /// Either disable the login item and start the manual child process, or vice-versa.
    private func updateRunMode() {
        if runAsLoginItem {
            stopManualHelperProcess()
        }
        guard SMLoginItemSetEnabled("com.TristanInc.Kasperl-Helper" as CFString, runAsLoginItem) == true else {
            let error = runAsLoginItem ? HelperControllerError.failedToAddAsLoginItem : HelperControllerError.failedToRemoveLoginItem
            presentError(error)
            return
        }
        if !runAsLoginItem {
            startManualHelperProcess()
        }
    }

    func presentError(_ error: Error) {
        NSApplication.shared.presentError(error)
    }

    static private let helperToolName = "Kasperl Helper"
    static private var helperToolURL: URL {
        Bundle.main.loginItemsURL.appendingPathComponent(helperToolName).appendingPathExtension("app")
    }

    enum HelperControllerError: Error {
        case failedToAddAsLoginItem
        case failedToRemoveLoginItem
        case couldNotFindHelperTool
        case failedToLaunchHelperTool
    }

}

extension Bundle {
    /// Returns the url the "LoginItems" directory inside the receiver.
    /// Unfortunately there does not seem to be a built in way to get this.
    var loginItemsURL: URL {
        self.bundleURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Library")
        .appendingPathComponent("LoginItems")
    }
}
