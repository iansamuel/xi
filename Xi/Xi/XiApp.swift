//
//  XiApp.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "YES_ACTION":
            print("User completed habit: \(userInfo["habitName"] ?? "Unknown")")
            // TODO: Mark habit as completed and update spaced repetition
        case "NO_ACTION":
            print("User did not complete habit: \(userInfo["habitName"] ?? "Unknown")")
            // TODO: Mark habit as not completed and update spaced repetition
        case "LATER_ACTION":
            print("User asked to be reminded later: \(userInfo["habitName"] ?? "Unknown")")
            // TODO: Reschedule for a shorter interval
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

@main
struct XiApp: App {
    let notificationDelegate = NotificationDelegate()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await NotificationManager.shared.requestPermission()
                    await NotificationManager.shared.checkPermissionStatus()
                    NotificationManager.shared.setupNotificationCategories()
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
