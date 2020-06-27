//
//  NotificationController.swift
//  Kasperl
//
//  Created by Matthias Keiser on 05/06/2020.
//  Copyright © 2020 Matthias Keiser. All rights reserved.
//

import AppKit
import UserNotifications
import os.log

/// Controls the display of user notifications.
class NotificationController: NSObject, UNUserNotificationCenterDelegate {

    weak var delegate: NotificationControllerDelegate?

    init(withDelegate delegate: NotificationControllerDelegate) {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        self.delegate = delegate
    }
    
    static func setup() {
        askForPermission()
        registerNotificationCategory()
    }

    static func askForPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, error in
            guard granted else {
                self.handleNotificationError(error)
                return
            }
        }
    }

    static func registerNotificationCategory() {
        let category = UNNotificationCategory.warning
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([category])
    }

    func showNotification() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                  (settings.authorizationStatus == .provisional) else { return }

            if settings.alertSetting == .enabled {
                UNUserNotificationCenter.current().add(UNNotificationRequest.warning) { (error) in
                   if let error = error {
                    NotificationController.handleNotificationError(error)
                   }
                }

            } else {

            }
        }
    }

    // TODO: We probably should inform the user that it does not make sense to run this
    // app with notifications disabled.
    static func handleNotificationError(_ error: Error?) {
        os_log("Failed to get notification authorization: %{public}@?", error?.localizedDescription ?? "<nil>")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        // First try standard identifiers
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            self.delegate?.userRequestedBringAppToForeground(self)
            return
        case UNNotificationDismissActionIdentifier:
            self.delegate?.userDismissedNotification(self)
            return
        default:
            break;
        }

        // Next try custom identifiers
        switch NotificationAction(rawValue: response.actionIdentifier) {
        case .quitConsole:
            self.delegate?.userRequestedQuitConsole(self)
        case nil:
            print("unknown response identifier: \(response.actionIdentifier)")
        }
    }
}

protocol NotificationControllerDelegate: AnyObject {

    func userRequestedQuitConsole(_ notificationController: NotificationController)
    func userRequestedBringAppToForeground(_ notificationController: NotificationController)
    func userDismissedNotification(_ notificationController: NotificationController)
}

private enum NotificationAction: String {
    case quitConsole
}

extension UNNotificationCategory {

    static let warning: UNNotificationCategory = {

        enum Category: String {
            case backgroundWarning
        }

        let quitAction = UNNotificationAction(
            identifier: NotificationAction.quitConsole.rawValue,
            title: NSLocalizedString("Quit Console", comment: "Quit console notification action title"),
            options: []
        )

        return UNNotificationCategory(
            identifier: Category.backgroundWarning.rawValue,
            actions: [quitAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: .customDismissAction)
    }()
}

extension UNNotificationRequest {

    static var warning: UNNotificationRequest = {

        let notificationIdentifier = "E46BE5B6-3DD3-4601-B0C4-15958F3CA8D9"

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Console is running in the background", comment: "Console warning notification title")
        content.body = NSLocalizedString("Do you want to quit it?", comment: "Console warning notification subtitle")
        content.categoryIdentifier = UNNotificationCategory.warning.identifier
        return UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: nil)
    }()
}
