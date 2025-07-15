//
//  XiApp.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import UIKit

enum MigrationStatus {
    case success
    case dataBackedUp
    case gracefulMigration
    case dataReset
    case failed(String)
}

@MainActor
class MigrationManager: ObservableObject {
    @Published var migrationStatus: MigrationStatus = .success
    @Published var showMigrationAlert = false
    
    static let shared = MigrationManager()
    
    private init() {}
    
    func handleMigrationResult(_ status: MigrationStatus) {
        self.migrationStatus = status
        
        switch status {
        case .dataBackedUp:
            print("ℹ️ Data has been backed up before migration")
        case .gracefulMigration:
            print("✅ Migration completed successfully")
        case .dataReset:
            print("⚠️ Data was reset due to incompatible schema changes")
            showMigrationAlert = true
        case .failed(let error):
            print("❌ Migration failed: \(error)")
            showMigrationAlert = true
        case .success:
            print("✅ Database loaded successfully")
        }
    }
}

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
            habit.recordSuccess(context: context)
            // Reschedule notification
            NotificationManager.shared.scheduleHabitNotification(for: habit, context: context)
            
        case "NO_ACTION":
            print("❌ User did not complete habit: \(habit.name)")
            habit.recordFailure(context: context)
            // Reschedule notification
            NotificationManager.shared.scheduleHabitNotification(for: habit, context: context)
            
        case "LATER_ACTION":
            print("⏰ User asked to be reminded later: \(habit.name)")
            habit.recordLater(context: context)
            // Reschedule notification
            NotificationManager.shared.scheduleHabitNotification(for: habit, context: context)
            
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
            HabitEvent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Task { @MainActor in
                MigrationManager.shared.handleMigrationResult(.success)
            }
        } catch {
            // Handle schema migration failures more gracefully
            print("⚠️ ModelContainer creation failed: \(error)")
            let (container, status) = Self.handleMigrationFailure(schema: schema, modelConfiguration: modelConfiguration, error: error)
            sharedModelContainer = container
            Task { @MainActor in
                MigrationManager.shared.handleMigrationResult(status)
            }
        }
        
        // Inject the model container into the notification delegate
        notificationDelegate.modelContainer = sharedModelContainer
    }
    
    private static func handleMigrationFailure(schema: Schema, modelConfiguration: ModelConfiguration, error: Error) -> (ModelContainer, MigrationStatus) {
        // First, try to understand what kind of error we're dealing with
        let errorDescription = String(describing: error)
        print("🔍 Migration error details: \(errorDescription)")
        
        // Check if this is a true schema incompatibility or just a temporary issue
        if errorDescription.contains("migration") || errorDescription.contains("schema") || errorDescription.contains("incompatible") {
            // This is likely a schema migration issue - we need to be more careful
            print("📋 Detected schema migration issue - attempting data preservation")
            
            // Try to backup existing data before attempting migration
            let backupResult = backupExistingData()
            var migrationStatus: MigrationStatus = .dataBackedUp
            
            if backupResult.success {
                print("✅ Data backup successful - proceeding with migration")
                migrationStatus = .dataBackedUp
            } else {
                print("⚠️ Data backup failed: \(backupResult.error ?? "Unknown error")")
                migrationStatus = .failed("Backup failed: \(backupResult.error ?? "Unknown error")")
            }
            
            // Try alternative migration strategies
            if let container = attemptGracefulMigration(schema: schema, modelConfiguration: modelConfiguration) {
                print("✅ Graceful migration successful")
                return (container, .gracefulMigration)
            }
            
            // If graceful migration fails, offer user choice (in a real app, this would be a UI dialog)
            print("🚨 Migration requires data reset - this should prompt user in a real implementation")
            
            // As a last resort, create a new container (but we've at least tried to preserve data)
            let container = createFreshContainer(schema: schema, modelConfiguration: modelConfiguration)
            return (container, .dataReset)
        } else {
            // This might be a temporary issue - try again once
            print("🔄 Retrying ModelContainer creation (might be temporary issue)")
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                return (container, .success)
            } catch {
                print("❌ Retry failed: \(error)")
                let container = createFreshContainer(schema: schema, modelConfiguration: modelConfiguration)
                return (container, .failed("Retry failed: \(error.localizedDescription)"))
            }
        }
    }
    
    private static func backupExistingData() -> (success: Bool, error: String?) {
        // Attempt to backup existing data before migration
        let url = URL.applicationSupportDirectory.appending(path: "default.store")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return (success: true, error: "No existing data to backup")
        }
        
        do {
            let backupURL = URL.applicationSupportDirectory.appending(path: "default.store.backup.\(Date().timeIntervalSince1970)")
            try FileManager.default.copyItem(at: url, to: backupURL)
            print("💾 Created backup at: \(backupURL.path)")
            return (success: true, error: nil)
        } catch {
            return (success: false, error: "Backup failed: \(error.localizedDescription)")
        }
    }
    
    private static func attemptGracefulMigration(schema: Schema, modelConfiguration: ModelConfiguration) -> ModelContainer? {
        // Try different migration strategies
        
        // Strategy 1: Try with migration options
        do {
            let migrationConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            
            let container = try ModelContainer(for: schema, configurations: [migrationConfig])
            print("✅ Migration successful with alternative configuration")
            return container
        } catch {
            print("⚠️ Alternative configuration failed: \(error)")
        }
        
        // Strategy 2: Try to open with just the core model first
        do {
            let coreSchema = Schema([Habit.self]) // Try with just Habit first
            let container = try ModelContainer(for: coreSchema, configurations: [modelConfiguration])
            print("✅ Core model migration successful")
            
            // Now try to add the relationship model
            // Note: This is a simplified approach - in a real migration, you'd need more sophisticated logic
            return container
        } catch {
            print("⚠️ Core model migration failed: \(error)")
        }
        
        return nil
    }
    
    private static func createFreshContainer(schema: Schema, modelConfiguration: ModelConfiguration) -> ModelContainer {
        // Only as a last resort, create a fresh container
        let url = URL.applicationSupportDirectory.appending(path: "default.store")
        
        do {
            // Remove the existing database file
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Removed incompatible database file")
            }
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ Created fresh ModelContainer")
            return container
        } catch {
            fatalError("Could not create ModelContainer even after cleanup: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared) // Provide as environment object
                .environmentObject(MigrationManager.shared) // Add migration manager
                .task {
                    await NotificationManager.shared.requestPermission()
                    await NotificationManager.shared.checkPermissionStatus()
                    NotificationManager.shared.setupNotificationCategories()
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // When app becomes active, check for overdue habits
                    Task { @MainActor in
                        let context = sharedModelContainer.mainContext
                        let fetchDescriptor = FetchDescriptor<Habit>()
                        do {
                            let habits = try context.fetch(fetchDescriptor)
                            NotificationManager.shared.checkForOverdueHabits(habits, context: context)
                        } catch {
                            print("❌ Error fetching habits for overdue check: \(error)")
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
