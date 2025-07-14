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
    
    // Relationship to HabitEvents for tracking
    @Relationship(deleteRule: .cascade, inverse: \HabitEvent.habit)
    var events: [HabitEvent] = []
    
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
    
    // Computed properties for tracking based on logged events
    var successRate: Double {
        let responseEvents = events.filter { $0.isResponse }
        guard !responseEvents.isEmpty else { return 0.0 }
        
        let successCount = responseEvents.filter { $0.isSuccess }.count
        return Double(successCount) / Double(responseEvents.count) * 100.0
    }
    
    var streakCount: Int {
        // Calculate current streak from recent events
        let responseEvents = events.filter { $0.isResponse }
            .sorted { $0.timestamp > $1.timestamp } // Most recent first
        
        var streak = 0
        for event in responseEvents {
            if event.isSuccess {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    // Additional computed properties for analytics
    var totalResponses: Int {
        return events.filter { $0.isResponse }.count
    }
    
    var totalReminders: Int {
        return events.filter { $0.isReminder }.count
    }
    
    var recentEvents: [HabitEvent] {
        return events.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Spaced Repetition Methods
    
    func recordSuccess(context: ModelContext) {
        // Log the success event
        let event = HabitEvent(eventType: .responseSuccess, habit: self, intervalUsed: currentInterval)
        context.insert(event)
        
        // Update legacy counters for compatibility
        totalAttempts += 1
        successfulAttempts += 1
        lastCheckedAt = Date()
        
        // Increase interval on success (spaced repetition)
        currentInterval = min(currentInterval * easeFactor, maximumInterval)
        scheduleNextNotification()
    }
    
    func recordFailure(context: ModelContext) {
        // Log the failure event
        let event = HabitEvent(eventType: .responseFailure, habit: self, intervalUsed: currentInterval)
        context.insert(event)
        
        // Update legacy counters for compatibility
        totalAttempts += 1
        lastCheckedAt = Date()
        
        // Decrease interval on failure (more frequent reminders)
        currentInterval = max(currentInterval / 2.0, minimumInterval)
        scheduleNextNotification()
    }
    
    func recordLater(context: ModelContext) {
        // Log the later event
        let event = HabitEvent(eventType: .responseLater, habit: self, intervalUsed: currentInterval)
        context.insert(event)
        
        // Don't count as attempt, just reschedule sooner
        currentInterval = max(currentInterval / 3.0, minimumInterval)
        scheduleNextNotification()
    }
    
    func logReminderSent(context: ModelContext) {
        // Log when a reminder is sent
        let event = HabitEvent(eventType: .reminderSent, habit: self, intervalUsed: currentInterval)
        context.insert(event)
    }
    
    func logOverduePrompt(context: ModelContext) {
        // Log when an overdue prompt is shown
        let event = HabitEvent(eventType: .overduePrompt, habit: self, intervalUsed: currentInterval)
        context.insert(event)
    }
    
    private func scheduleNextNotification() {
        nextNotificationDate = Date().addingTimeInterval(currentInterval)
    }
}
