//
//  NotificationManager.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var habitToConfirm: Habit? // New property to hold the habit for confirmation
    @Published var overdueHabitsQueue: [Habit] = [] // Queue of overdue habits to prompt for
    
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
    
    func scheduleHabitNotification(for habit: Habit, context: ModelContext? = nil) {
        guard hasPermission else { return }
        
        // Remove any existing notification for this habit
        cancelNotification(for: habit)
        
        let content = UNMutableNotificationContent()
        content.title = "Xi Habit Check"
        content.body = "Did you do your habit: \(habit.name)?"
        content.sound = .default
        content.categoryIdentifier = "HABIT_CHECK"
        content.userInfo = [
            "habitId": habit.persistentModelID.hashValue,
            "habitName": habit.name
        ]
        
        // Schedule for the next notification date
        let timeInterval = habit.nextNotificationDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return } // Don't schedule past dates
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "habit_\(habit.persistentModelID.hashValue)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("✅ Scheduled notification for \(habit.name) at \(habit.nextNotificationDate)")
                
                // Log the reminder if context is provided
                if let context = context {
                    Task { @MainActor in
                        habit.logReminderSent(context: context)
                        try? context.save()
                    }
                }
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
            "habitId": habit.persistentModelID.hashValue,
            "habitName": habit.name,
            "isTest": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_habit_\(habit.persistentModelID.hashValue)",
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
        let regularIdentifier = "habit_\(habit.persistentModelID.hashValue)"
        let testIdentifier = "test_habit_\(habit.persistentModelID.hashValue)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [regularIdentifier, testIdentifier])
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
            title: "No, I forgot",
            options: []
        )
        
        let laterAction = UNNotificationAction(
            identifier: "LATER_ACTION",
            title: "Haven't had a chance yet",
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
    
    // MARK: - Overdue Habit Management
    
    func checkForOverdueHabits(_ habits: [Habit], context: ModelContext? = nil) {
        let now = Date()
        let overdueHabits = habits.filter { habit in
            habit.isActive && habit.nextNotificationDate < now
        }
        
        if !overdueHabits.isEmpty {
            print("📋 Found \(overdueHabits.count) overdue habits")
            overdueHabitsQueue = overdueHabits
            
            // Log overdue prompts for each habit
            if let context = context {
                for habit in overdueHabits {
                    habit.logOverduePrompt(context: context)
                }
                try? context.save()
            }
            
            processNextOverdueHabit()
        }
    }
    
    private func processNextOverdueHabit() {
        guard !overdueHabitsQueue.isEmpty else { return }
        
        // If we're already showing a habit confirmation, don't show another
        guard habitToConfirm == nil else { return }
        
        let nextHabit = overdueHabitsQueue.removeFirst()
        print("⏰ Showing overdue habit: \(nextHabit.name)")
        habitToConfirm = nextHabit
    }
    
    func markCurrentHabitCompleted() {
        habitToConfirm = nil
        // Process next overdue habit if any remain
        processNextOverdueHabit()
    }
}