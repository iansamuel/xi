//
//  HabitEvent.swift
//  Xi
//
//  Created by Ian Samuel on 7/14/25.
//

import Foundation
import SwiftData

@Model
final class HabitEvent {
    var timestamp: Date
    var eventType: EventType
    var habit: Habit
    var intervalUsed: TimeInterval? // The interval that was used for this event
    var notes: String? // Additional context or metadata
    
    enum EventType: String, CaseIterable, Codable {
        case reminderSent = "reminder_sent"
        case responseSuccess = "response_success"
        case responseFailure = "response_failure"
        case responseLater = "response_later"
        case overduePrompt = "overdue_prompt"
    }
    
    init(eventType: EventType, habit: Habit, intervalUsed: TimeInterval? = nil, notes: String? = nil) {
        self.timestamp = Date()
        self.eventType = eventType
        self.habit = habit
        self.intervalUsed = intervalUsed
        self.notes = notes
    }
    
    // Computed properties for easy analysis
    var isReminder: Bool {
        eventType == .reminderSent || eventType == .overduePrompt
    }
    
    var isResponse: Bool {
        eventType == .responseSuccess || eventType == .responseFailure || eventType == .responseLater
    }
    
    var isSuccess: Bool {
        eventType == .responseSuccess
    }
    
    var isFailure: Bool {
        eventType == .responseFailure
    }
    
    var isLater: Bool {
        eventType == .responseLater
    }
}