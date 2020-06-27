//
//  AppDelegate.swift
//  Kasperl
//
//  Created by Matthias Keiser on 05/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import Cocoa
import os.log

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let helperController = HelperController()
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        do {
            try helperController.start()
        } catch {
            NSApplication.shared.presentError(error)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        do {
            try helperController.stop()
        } catch {
            os_log("Error quitting helper app: %{public}@?", error.localizedDescription)
        }
    }
}

