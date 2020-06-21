//
//  AppController.swift
//  Konsole Kasperl
//
//  Created by Matthias Keiser on 09/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import Foundation

class AppController: LoginItemPreferenceObserverDelegate {

    lazy private(set) var loginItemPreferenceObserver = LoginItemPreferenceObserver(delegate: self)
    lazy private(set) var helperController = HelperController(runAsLoginItem: loginItemPreferenceObserver.loginItemEnabled)

    func start() {
        loginItemPreferenceObserver.start()
        helperController.start()
    }

    // MARK: LoginItemControllerDelegate

    func loginItemPreferenceDidChange(_ observer: LoginItemPreferenceObserver) {
        helperController.runAsLoginItem = observer.loginItemEnabled
    }

}
