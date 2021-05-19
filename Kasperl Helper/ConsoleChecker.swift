//
//  ConsoleChecker.swift
//  Kasperl
//
//  Created by Matthias Keiser on 05/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import AppKit
import os

let consoleAppBundleID = "com.apple.Console"

class ConsoleMonitor: NSObject {

    weak var delegate: ConsoleMonitorDelegate?
    private var intervalTier = IntervalTier()
    private var warnNextCheck = false
    private var timer: Timer? {
        willSet { timer?.invalidate() }
    }

    init(withDelegate delegate: ConsoleMonitorDelegate) {
        self.delegate = delegate
    }

    private func getNotifiedWhenAnyAppResignsActive() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(Self.someAppDidResignActive(_:)), notificationNames: Notification.Name.resignActiveNotifications)
    }

    @objc private func someAppDidResignActive(_ note: Notification) {
        if note.isConsoleAppNotification {
            self.consoleAppDidResignActive()
        }
    }

    private func getNotifiedWhenAnyAppActivatesOrQuits() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(Self.someAppDidActivateOrQuit(_:)), notificationNames: Notification.Name.activateOrQuitNotifications)
    }

    @objc private func someAppDidActivateOrQuit(_ note: Notification) {
        if note.isConsoleAppNotification {
            self.consoleAppDidActivateOrQuit()
        }
    }

    func consoleAppDidResignActive() {
        NSWorkspace.shared.notificationCenter.removeObserver(self, notificationNames: Notification.Name.resignActiveNotifications)
        self.doStartMonitoring()
    }

    func consoleAppDidActivateOrQuit() {
        NSWorkspace.shared.notificationCenter.removeObserver(self, notificationNames: Notification.Name.activateOrQuitNotifications)
        self.doStopMonitoring()
        self.getNotifiedWhenAnyAppResignsActive()
    }

    /// Starts monitoring the console app.
    private func doStartMonitoring() {
        // reset this flag
        self.warnNextCheck = false
        // check current status immediately (might modify warnNextCheck again)
        self.checkIfConsoleRunningInBackground()
        // start the timer
        self.startTimer()
    }

    private func resetAndStart() {
        self.intervalTier.reset()
        if NSWorkspace.shared.isConsoleRunningInBackground {
            self.doStartMonitoring()
        } else {
            self.getNotifiedWhenAnyAppResignsActive()
        }
    }

    private func startTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: self.intervalTier.timeInterval, repeats: false) { [weak self] _ in
            self?.checkIfConsoleRunningInBackground()
        }
        self.timer?.tolerance = 3
    }

    private func doStopMonitoring() {
        self.timer?.invalidate()
    }

    /// Checks the current state of the Console.app. If Console is running in the background and `warnNextCheck` is true, triggers a
    /// user notification, else it sets `warnNextCheck` to `true`.
    private func checkIfConsoleRunningInBackground() {
        let runningInBackground = NSWorkspace.shared.isConsoleRunningInBackground

        if (runningInBackground && warnNextCheck) {
            self.triggerUserNotification()
        } else {
            self.warnNextCheck = runningInBackground
        }
    }

    private func triggerUserNotification() {
        self.increaseTimeInterval()
        self.delegate?.doNotify(monitor: self)
    }

    private func increaseTimeInterval() {
        self.intervalTier.increase()
        self.startTimer()
    }
}

// MARK: Public API

extension ConsoleMonitor {

    /// Start observing the Console.app status. The receiver will monitor the status of the Console application, and if it
    /// stays inactive for longer periods of time, it will inform the delegate.
    func start() {
        self.resetAndStart()
    }

    /// Quits the Console.app.
    func quitConsole() {
        guard let consoleApp = NSWorkspace.shared.runningConsoleApp else {
            return
        }
        guard consoleApp.terminate() else {
            NSSound.beep()
            // We failed to terminate the app, at least try to bring it to the foreground so
            // that the user can deal with it manually.
            consoleApp.activate(options: [])
            return
        }
        self.resetAndStart()
    }

    /// Informs the receiver that the user dismissed our notification. We take this opportunity to
    /// restart the timer since we don't want to annoy the user with a new notification right away.
    func userDismissed() {
        self.startTimer()
    }
}

protocol ConsoleMonitorDelegate: AnyObject {
    func doNotify(monitor: ConsoleMonitor)
}

// MARK: Utilities

private struct IntervalTier {
    static let unit: TimeInterval = 60
    private static let intervalTiers: [TimeInterval] = [1*unit, 5*unit, 10*unit, 20*unit, 40*unit, 60*unit]
    private var tierIndex = 0

    mutating func reset() {
        self.tierIndex = 0
    }
    mutating func increase() {
        self.tierIndex = min(tierIndex+1, IntervalTier.intervalTiers.endIndex)
    }

    var timeInterval: TimeInterval {
        IntervalTier.intervalTiers[tierIndex]
    }
}

private extension NSWorkspace {
    /// Returns the running instance of Console.app, if any.
    var runningConsoleApp: NSRunningApplication? {
        return NSWorkspace.shared.runningApplications.first { $0.isConsoleApp }
    }

    /// Returns true if Console.app is running in the background.
    /// Observing this and reporting it really is the whole purpose of this little app.
    var isConsoleRunningInBackground: Bool {
        runningConsoleApp?.isActive == false
    }
}

private extension NSRunningApplication {
    var isConsoleApp: Bool {
        self.bundleIdentifier == consoleAppBundleID
    }
}

private extension Notification {
    var isConsoleAppNotification: Bool {
        (self.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.isConsoleApp == true
    }
}

private extension Notification.Name {
    static var resignActiveNotifications: [Self] = [
        NSWorkspace.didHideApplicationNotification,
        NSWorkspace.didDeactivateApplicationNotification
    ]

    static var activateOrQuitNotifications: [Self] = [
        NSWorkspace.didActivateApplicationNotification,
        NSWorkspace.didUnhideApplicationNotification,
        NSWorkspace.didTerminateApplicationNotification
    ]
}

extension NotificationCenter {
    func addObserver(_ observer: Any, selector: Selector, notificationNames: [Notification.Name], object: Any? = nil) {
        notificationNames.forEach {
            self.addObserver(observer, selector: selector, name: $0, object: object)
        }
    }

    func removeObserver(_ observer: Any, notificationNames: [Notification.Name], object: Any? = nil) {
        notificationNames.forEach {
            self.removeObserver(observer, name: $0, object: object)
        }
    }

}
