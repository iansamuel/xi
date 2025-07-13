//
//  Habit.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var habitDescription: String
    var createdAt: Date
    var currentInterval: TimeInterval // Current interval between notifications (in seconds)
    var nextNotificationDate: Date
    var totalAttempts: Int
    var successfulAttempts: Int
    var lastCheckedAt: Date?
    var isActive: Bool
    var selectedIcon: String // Store the selected icon (emoji or symbol name)
    var frequency: String // Store selected frequency (Daily, Weekly, Monthly, Custom)
    
    // Spaced repetition parameters
    var easeFactor: Double // How much to multiply interval on success
    var minimumInterval: TimeInterval // Minimum time between notifications
    var maximumInterval: TimeInterval // Maximum time between notifications
    
    init(name: String, habitDescription: String = "") {
        self.name = name
        self.habitDescription = habitDescription
        self.createdAt = Date()
        self.currentInterval = 3600 // Start with 1 hour
        self.nextNotificationDate = Date().addingTimeInterval(3600)
        self.totalAttempts = 0
        self.successfulAttempts = 0
        self.lastCheckedAt = nil
        self.isActive = true
        self.selectedIcon = "⭐" // Default star emoji
        self.frequency = "Daily" // Default frequency
        
        // Default spaced repetition settings
        self.easeFactor = 1.5 // Increase interval by 50% on success
        self.minimumInterval = 1800 // 30 minutes minimum
        self.maximumInterval = 86400 * 7 // 1 week maximum
    }
    
    // Computed properties for tracking
    var successRate: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(successfulAttempts) / Double(totalAttempts)
    }
    
    var streakCount: Int {
        // This would need to be calculated from a history of check-ins
        // For now, return a simple calculation
        return successfulAttempts
    }
    
    // MARK: - Spaced Repetition Methods
    
    func recordSuccess() {
        totalAttempts += 1
        successfulAttempts += 1
        lastCheckedAt = Date()
        
        // Increase interval on success (spaced repetition)
        currentInterval = min(currentInterval * easeFactor, maximumInterval)
        scheduleNextNotification()
    }
    
    func recordFailure() {
        totalAttempts += 1
        lastCheckedAt = Date()
        
        // Decrease interval on failure (more frequent reminders)
        currentInterval = max(currentInterval / 2.0, minimumInterval)
        scheduleNextNotification()
    }
    
    func recordLater() {
        // Don't count as attempt, just reschedule sooner
        currentInterval = max(currentInterval / 3.0, minimumInterval)
        scheduleNextNotification()
    }
    
    private func scheduleNextNotification() {
        nextNotificationDate = Date().addingTimeInterval(currentInterval)
    }
}
