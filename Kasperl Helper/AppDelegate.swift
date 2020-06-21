//
//  AppDelegate.swift
//  Kasperl Helper
//
//  Created by Matthias Keiser on 06/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let mainController = HelperAppController()
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationController.setup()
        mainController.start()
    }
}

