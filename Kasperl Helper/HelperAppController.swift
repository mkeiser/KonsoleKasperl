//
//  MainController.swift
//  Kasperl Helper
//
//  Created by Matthias Keiser on 06/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import AppKit

let parentBundleID = "com.TristanInc.Kasperl"

/// The main controller for the helper app. Ties together the ConsoleMonitor and the NotificationController.
class HelperAppController: NSObject, ConsoleMonitorDelegate, NotificationControllerDelegate {

    func start() {
        setupMonitor()
    }

    var monitor: ConsoleMonitor?
    var notificationController: NotificationController?

    func setupMonitor() {
        self.notificationController = NotificationController(withDelegate: self)
        self.monitor = ConsoleMonitor(withDelegate: self)
        self.monitor?.start()
    }

    // MARK: ConsoleMonitorDelegate

    func doNotify(monitor: ConsoleMonitor) {
        notificationController?.showNotification()
    }

    // MARK: NotificationControllerDelegate

    func userRequestedQuitConsole(_ notificationController: NotificationController) {
        self.monitor?.quitConsole()
    }

    func userRequestedBringAppToForeground(_ notificationController: NotificationController) {
        NSWorkspace.shared.launchApplication(withBundleIdentifier: parentBundleID, options: .`default`, additionalEventParamDescriptor: nil, launchIdentifier: nil)
    }

    func userDismissedNotification(_ notificationController: NotificationController) {
        self.monitor?.userDismissed()
    }
}


