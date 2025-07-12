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
    var modelContainer: ModelContainer?
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        guard let habitIdHash = userInfo["habitId"] as? Int else {
            print("❌ No habitId found in notification")
            completionHandler()
            return
        }
        
        Task { @MainActor in
            await self.handleHabitResponse(response.actionIdentifier, habitIdHash: habitIdHash)
        }
        
        completionHandler()
    }
    
    @MainActor
    private func handleHabitResponse(_ actionIdentifier: String, habitIdHash: Int) async {
        // Get the model context from the injected container
        guard let container = modelContainer else {
            print("❌ No model container available")
            return
        }
        
        let context = container.mainContext
        
        // Find the habit by hash value
        let fetchDescriptor = FetchDescriptor<Habit>()
        do {
            let habits = try context.fetch(fetchDescriptor)
            guard let habit = habits.first(where: { $0.persistentModelID.hashValue == habitIdHash }) else {
                print("❌ Could not find habit with hash: \(habitIdHash)")
                return
            }
            
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
            try context.save()
            
        } catch {
            print("❌ Error handling habit response: \(error)")
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
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Inject the model container into the notification delegate
        notificationDelegate.modelContainer = sharedModelContainer
    }

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
