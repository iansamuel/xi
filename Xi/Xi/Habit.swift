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
    var consecutiveSuccesses: Int // Track consecutive successes for interval progression
    var currentIntervalMultiplier: Int // Current interval multiplier (1 = base frequency, 2 = double, etc.)
    
    // Legacy spaced repetition parameters (kept for compatibility)
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
        self.currentInterval = 24 * 60 * 60 // Start with 1 day (will be updated based on frequency)
        self.nextNotificationDate = Date().addingTimeInterval(24 * 60 * 60)
        self.totalAttempts = 0
        self.successfulAttempts = 0
        self.lastCheckedAt = nil
        self.isActive = true
        self.selectedIcon = "⭐" // Default star emoji
        self.frequency = "Daily" // Default frequency
        
        // New frequency-based spaced repetition
        self.consecutiveSuccesses = 0
        self.currentIntervalMultiplier = 1 // Start with base frequency
        
        // Default spaced repetition settings (legacy)
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
    
    // MARK: - Frequency-Based Interval Helpers
    
    private var baseInterval: TimeInterval {
        switch frequency {
        case "Daily":
            return 24 * 60 * 60 // 1 day in seconds
        case "Weekly":
            return 7 * 24 * 60 * 60 // 1 week in seconds
        case "Monthly":
            return 30 * 24 * 60 * 60 // 1 month in seconds (approximation)
        default:
            return 24 * 60 * 60 // Default to daily
        }
    }
    
    private var currentFrequencyInterval: TimeInterval {
        return baseInterval * TimeInterval(currentIntervalMultiplier)
    }
    
    // MARK: - Spaced Repetition Methods
    
    func recordSuccess(context: ModelContext) {
        // Log the success event
        let event = HabitEvent(eventType: .responseSuccess, habit: self, intervalUsed: currentFrequencyInterval)
        context.insert(event)
        
        // Update legacy counters for compatibility
        totalAttempts += 1
        successfulAttempts += 1
        lastCheckedAt = Date()
        
        // New frequency-based spaced repetition logic
        consecutiveSuccesses += 1
        
        // If 3 consecutive successes, increase interval multiplier
        if consecutiveSuccesses >= 3 {
            currentIntervalMultiplier += 1
            consecutiveSuccesses = 0 // Reset counter
            print("✅ Habit \(name) interval increased to \(currentIntervalMultiplier)x \(frequency.lowercased())")
        }
        
        // Update current interval to use frequency-based system
        currentInterval = currentFrequencyInterval
        scheduleNextNotification()
    }
    
    func recordFailure(context: ModelContext) {
        // Log the failure event
        let event = HabitEvent(eventType: .responseFailure, habit: self, intervalUsed: currentFrequencyInterval)
        context.insert(event)
        
        // Update legacy counters for compatibility
        totalAttempts += 1
        lastCheckedAt = Date()
        
        // New frequency-based spaced repetition logic
        // Reset to minimum interval on any failure
        consecutiveSuccesses = 0
        currentIntervalMultiplier = 1
        
        print("❌ Habit \(name) interval reset to 1x \(frequency.lowercased()) due to failure")
        
        // Update current interval to use frequency-based system
        currentInterval = currentFrequencyInterval
        scheduleNextNotification()
    }
    
    func recordLater(context: ModelContext) {
        // Log the later event
        let event = HabitEvent(eventType: .responseLater, habit: self, intervalUsed: currentFrequencyInterval)
        context.insert(event)
        
        // Don't count as attempt or affect consecutive successes
        // Just reschedule sooner (1/3 of current interval, minimum of base frequency)
        currentInterval = max(currentFrequencyInterval / 3.0, baseInterval)
        scheduleNextNotification()
        
        print("⏰ Habit \(name) rescheduled sooner, keeping current interval multiplier (\(currentIntervalMultiplier)x)")
    }
    
    func logReminderSent(context: ModelContext) {
        // Log when a reminder is sent
        let event = HabitEvent(eventType: .reminderSent, habit: self, intervalUsed: currentFrequencyInterval)
        context.insert(event)
    }
    
    func logOverduePrompt(context: ModelContext) {
        // Log when an overdue prompt is shown
        let event = HabitEvent(eventType: .overduePrompt, habit: self, intervalUsed: currentFrequencyInterval)
        context.insert(event)
    }
    
    private func scheduleNextNotification() {
        nextNotificationDate = Date().addingTimeInterval(currentInterval)
    }
    
    // Call this when frequency changes to update intervals
    func updateIntervalForFrequency() {
        currentInterval = currentFrequencyInterval
        scheduleNextNotification()
    }
}
