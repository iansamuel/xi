//
//  XiApp.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications

import SwiftData

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var modelContainer: ModelContainer?
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        guard let habitIdHash = userInfo["habitId"] as? Int else {
            print("❌ No habitId found in notification")
            completionHandler()
            return
        }
        
        Task { @MainActor in
            // Get the model context from the injected container
            guard let container = modelContainer else {
                print("❌ No model container available")
                completionHandler()
                return
            }
            
            let context = container.mainContext
            
            // Find the habit by hash value
            let fetchDescriptor = FetchDescriptor<Habit>()
            do {
                let habits = try context.fetch(fetchDescriptor)
                guard let habit = habits.first(where: { $0.persistentModelID.hashValue == habitIdHash }) else {
                    print("❌ Could not find habit with hash: \(habitIdHash)")
                    completionHandler()
                    return
                }
                
                if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                    // User tapped the notification body, present the confirmation view
                    print("✅ Notification tapped for habit: \(habit.name). Setting habitToConfirm.")
                    // Dispatch to main queue to ensure UI updates happen on main thread
                    DispatchQueue.main.async {
                        NotificationManager.shared.habitToConfirm = habit
                    }
                } else {
                    // User selected an interactive action (YES, NO, LATER)
                    await self.handleHabitResponse(response.actionIdentifier, habit: habit, context: context)
                }
                
            } catch {
                print("❌ Error handling notification response: \(error)")
            }
            completionHandler()
        }
    }
    
    @MainActor
    private func handleHabitResponse(_ actionIdentifier: String, habit: Habit, context: ModelContext) async {
        switch actionIdentifier {
        case "YES_ACTION":
            print("✅ User completed habit: \(habit.name)")
            habit.recordSuccess()
            // Reschedule notification
            NotificationManager.shared.scheduleHabitNotification(for: habit)
            
        case "NO_ACTION":
            print("❌ User did not complete habit: \(habit.name)")
            habit.recordFailure()
            // Reschedule notification
            NotificationManager.shared.scheduleHabitNotification(for: habit)
            
        case "LATER_ACTION":
            print("⏰ User asked to be reminded later: \(habit.name)")
            habit.recordLater()
            // Reschedule notification
            NotificationManager.shared.scheduleHabitNotification(for: habit)
            
        default:
                break
        }
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("❌ Error saving context after habit response: \(error)")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

@main
struct XiApp: App {
    let notificationDelegate = NotificationDelegate()
    let sharedModelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Habit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If schema migration fails, try to recreate with a new configuration
            print("⚠️ ModelContainer creation failed, attempting to recreate: \(error)")
            do {
                // Force recreate the container - this will clear existing data but fix schema issues
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    print("🗑️ Removed old database file for schema migration")
                }
                
                sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ Successfully recreated ModelContainer")
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
        
        // Inject the model container into the notification delegate
        notificationDelegate.modelContainer = sharedModelContainer
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared) // Provide as environment object
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
