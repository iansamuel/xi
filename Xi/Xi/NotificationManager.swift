//
//  NotificationManager.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    private init() {}
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            hasPermission = granted
        } catch {
            print("Error requesting notification permission: \(error)")
            hasPermission = false
        }
    }
    
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized
    }
    
    func scheduleHabitNotification(for habit: Habit) {
        guard hasPermission else { return }
        
        // Remove any existing notification for this habit
        cancelNotification(for: habit)
        
        let content = UNMutableNotificationContent()
        content.title = "Xi Habit Check"
        content.body = "Did you do your habit: \(habit.name)?"
        content.sound = .default
        content.categoryIdentifier = "HABIT_CHECK"
        content.userInfo = [
            "habitId": habit.persistentModelID.uriRepresentation().absoluteString,
            "habitName": habit.name
        ]
        
        // Schedule for the next notification date
        let timeInterval = habit.nextNotificationDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return } // Don't schedule past dates
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "habit_\(habit.persistentModelID.uriRepresentation().absoluteString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("✅ Scheduled notification for \(habit.name) at \(habit.nextNotificationDate)")
            }
        }
    }
    
    func scheduleTestNotification(for habit: Habit, delay: TimeInterval) {
        guard hasPermission else { 
            print("❌ No notification permission")
            return 
        }
        
        // Remove any existing notification for this habit
        cancelNotification(for: habit)
        
        let content = UNMutableNotificationContent()
        content.title = "Xi Habit Check (TEST)"
        content.body = "Did you do your habit: \(habit.name)? This is a test notification."
        content.sound = .default
        content.categoryIdentifier = "HABIT_CHECK"
        content.userInfo = [
            "habitId": habit.persistentModelID.uriRepresentation().absoluteString,
            "habitName": habit.name,
            "isTest": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_habit_\(habit.persistentModelID.uriRepresentation().absoluteString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error)")
            } else {
                print("✅ Scheduled TEST notification for \(habit.name) in \(delay) seconds")
            }
        }
    }
    
    func cancelNotification(for habit: Habit) {
        let identifier = "habit_\(habit.persistentModelID.uriRepresentation().absoluteString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func setupNotificationCategories() {
        let yesAction = UNNotificationAction(
            identifier: "YES_ACTION",
            title: "Yes, I did it!",
            options: []
        )
        
        let noAction = UNNotificationAction(
            identifier: "NO_ACTION",
            title: "No, I didn't",
            options: []
        )
        
        let laterAction = UNNotificationAction(
            identifier: "LATER_ACTION",
            title: "Ask me later",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "HABIT_CHECK",
            actions: [yesAction, noAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📱 Pending notifications: \(requests.count)")
            for request in requests {
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    print("  - \(request.identifier): \(request.content.title) in \(trigger.timeInterval)s")
                }
            }
        }
    }
}