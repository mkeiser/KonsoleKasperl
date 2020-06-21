//
//  AppDelegate.swift
//  Kasperl
//
//  Created by Matthias Keiser on 05/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let appController = AppController()
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        appController.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }



}

