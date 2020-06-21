//
//  ConsoleChecker.swift
//  Kasperl
//
//  Created by Matthias Keiser on 05/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import AppKit

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

    private let startObservingTriggers = [
        NSWorkspace.didHideApplicationNotification,
        NSWorkspace.didDeactivateApplicationNotification
    ]

    private func startMonitoringOnNextDeactivate() {
        startObservingWorkspaceNotifications(startObservingTriggers, selector:  #selector(gotStartObservingNote(_:)))
    }

    @objc private func gotStartObservingNote(_ note: Notification) {
        if note.isConsoleAppNotification {
            stopObservingWorkspaceNotifications(startObservingTriggers)
            self.doStartMonitoring()
        }
    }

    private let stopObservingTriggers = [
        NSWorkspace.didActivateApplicationNotification,
        NSWorkspace.didUnhideApplicationNotification,
        NSWorkspace.didTerminateApplicationNotification
    ]

    private func stopMonitoringOnNextActivateOrQuit() {
        startObservingWorkspaceNotifications(stopObservingTriggers, selector:  #selector(gotStopObservingNote(_:)))
    }

    @objc private func gotStopObservingNote(_ note: Notification) {
        if note.isConsoleAppNotification {
            stopObservingWorkspaceNotifications(stopObservingTriggers)
            self.doStopMonitoring()
            startMonitoringOnNextDeactivate()
        }
    }

    /// Starts monitoring the console app.
    private func doStartMonitoring() {
        // reset this flag
        warnNextCheck = false
        // check current status immediately (might modify warnNextCheck again)
        checkIfConsoleRunningInBackground()
        // start the timer
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: self.intervalTier.timeInterval, repeats: false) { [weak self] _ in
            self?.checkIfConsoleRunningInBackground()
        }
        timer?.tolerance = 3
        print("checking in \(self.intervalTier.timeInterval) seconds, warnNextCheck = \(warnNextCheck)")
    }

    private func doStopMonitoring() {
        timer?.invalidate()
    }

    /// Checks the current state of the Console.app. If Console is running in the background and `warnNextCheck` is true, triggers a
    /// user notification, else it set `warnNextCheck` to true.
    private func checkIfConsoleRunningInBackground() {
        let runningInBackground = NSWorkspace.shared.isConsoleRunningInBackground

        if (runningInBackground && warnNextCheck) {
            self.triggerUserNotification()
        } else {
            self.warnNextCheck = runningInBackground
        }
    }

    private func triggerUserNotification() {
        increaseTimeInterval()
        delegate?.doNotify(monitor: self)
    }

    private func increaseTimeInterval() {
        self.intervalTier.increase()
        startTimer()
    }

    private func startObservingWorkspaceNotifications(_ notifications: [NSNotification.Name], selector: Selector) {
        notifications.forEach {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: selector, name: $0, object: nil)
        }
    }
    private func stopObservingWorkspaceNotifications(_ notifications: [NSNotification.Name]) {
        notifications.forEach {
            NSWorkspace.shared.notificationCenter.removeObserver(self, name: $0, object: nil)
        }
    }
}

// MARK: Public API

extension ConsoleMonitor {

    /// Start observing the Console.app status. The receiver will monitor the status of the Console application, and if it
    /// stays inactive for longer periods of time, it will inform the delegate.
    func start() {
        if NSWorkspace.shared.isConsoleRunningInBackground {
            doStartMonitoring()
        } else {
            startMonitoringOnNextDeactivate()
        }
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
        self.intervalTier.reset()
        startMonitoringOnNextDeactivate()
    }

    /// Informs the receiver that the user dismissed out notification. We take this opportunity to
    /// restart the timer since we don't want to annoy the user with a new notification right away.
    func userDismissed() {
        startTimer()
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
        tierIndex = 0
    }
    mutating func increase() {
        tierIndex = min(tierIndex+1, IntervalTier.intervalTiers.endIndex)
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
