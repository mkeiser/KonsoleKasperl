//
//  LoginItemController.swift
//  Kasperl
//
//  Created by Matthias Keiser on 06/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import AppKit

protocol LoginItemPreferenceObserverDelegate: AnyObject {
    func loginItemPreferenceDidChange(_ : LoginItemPreferenceObserver)
}

/// Observes the `startAtLogin` user pref and informs the delegate of changes.
/// It would be nicer to observe the login item state directly instead of using a pref. Using `SMCopyAllJobDictionaries`
/// seems to be the only alternative, but that function is both stupid _and_ deprecated.
class LoginItemPreferenceObserver: NSObject {

    weak var delegate: LoginItemPreferenceObserverDelegate?
    private var observation: NSKeyValueObservation?

    init(delegate: LoginItemPreferenceObserverDelegate) {
        self.delegate = delegate
        super.init()
    }

    func start() {
        // We pass `initial` here to make sure user pref and reality are in agreement.
        observation = UserDefaults.standard.observe(\UserDefaults.startAtLogin, options: .initial) { _, _ in
            self.delegate?.loginItemPreferenceDidChange(self)
        }
    }

    var loginItemEnabled: Bool {
        UserDefaults.standard.startAtLogin
    }
}

extension UserDefaults {
    /// A KVO-compatible extension to get the startAtLogin user default setting.
    @objc public var startAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "startAtLogin")}
        set { UserDefaults.standard.set(newValue, forKey: "startAtLogin")}
    }
}


