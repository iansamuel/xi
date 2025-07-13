# Xi

Xi (习) is a basic habit-development app for iOS that applies spaced repetition principles to habit formation. This is a pure experiment to explore whether the techniques that make Anki effective for learning can be adapted for building habits.

## Concept

The app sends local notifications asking if you've done a particular habit. Based on your response, it adjusts the interval before the next reminder:

- **Success**: Interval increases (spaced repetition - longer gaps between reminders)
- **Failure**: Interval decreases (more frequent practice)
- **"Haven't had a chance yet"**: Short retry without penalty

## Features

- Local notifications with interactive responses
- Adaptive interval scheduling based on performance
- Simple habit tracking and statistics
- Settings panel for testing and debugging
- Local storage only (no cloud sync)

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Local notification permissions

## Build Instructions

1. Open `Xi/Xi.xcodeproj` in Xcode
2. Select your development team for code signing
3. Build and run on device or simulator

For free Apple Developer accounts, CloudKit and remote notification capabilities have been removed.

## Implementation Notes

- Built with SwiftUI and SwiftData
- Uses UserNotifications framework for local notifications
- Spaced repetition algorithm in `Habit.swift`
- Notification response handling in `XiApp.swift`

## Background

"Xi" (习) means "habit" in Chinese. The McLaren orange icon reflects my favorite F1 team. This is an experimental project inspired by Anki's success with spaced repetition for learning, adapted to see if similar principles can help with habit formation.