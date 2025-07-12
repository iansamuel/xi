# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xi is a habit tracking app that uses spaced repetition to help users build habits. Users create habits, and Xi sends local notifications asking "did you do this habit?". Based on success/failure responses, Xi adjusts the notification intervals using spaced repetition algorithms - lengthening intervals on success, shortening on failure.

The app is built with SwiftUI, SwiftData for persistence, and UserNotifications for local notifications (no cloud setup required).

## Common Commands

### Building and Running
```bash
# Build the project
xcodebuild -project Xi.xcodeproj -scheme Xi -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device  
xcodebuild -project Xi.xcodeproj -scheme Xi -destination generic/platform=iOS build

# Clean build folder
xcodebuild -project Xi.xcodeproj clean
```

### Testing
```bash
# Run tests
xcodebuild test -project Xi.xcodeproj -scheme Xi -destination 'platform=iOS Simulator,name=iPhone 15'
```

Note: Xcode is required for building. If only Command Line Tools are installed, use Xcode IDE instead.

## Architecture

### Project Structure
```
Xi/
├── Xi/
│   ├── XiApp.swift              # App entry point with SwiftData container and notification delegate
│   ├── ContentView.swift        # Main UI with habit list, detail, and add views
│   ├── Habit.swift             # SwiftData model for habits with spaced repetition
│   ├── NotificationManager.swift # Local notification scheduling and management
│   ├── Assets.xcassets/        # App icons and assets
│   ├── Info.plist             # Background modes configuration
│   └── Xi.entitlements        # App sandbox and CloudKit entitlements
├── XiTests/                    # Unit tests using Swift Testing framework
└── XiUITests/                  # UI tests using XCTest framework
```

### Key Technologies
- **SwiftUI**: Declarative UI with NavigationSplitView, sheets, and forms
- **SwiftData**: Data persistence with @Model, @Query, and ModelContainer
- **UserNotifications**: Local notifications with interactive actions
- **Swift Testing**: Modern testing framework (unit tests)
- **XCTest**: Traditional testing framework (UI tests)

### Data Flow and Architecture
- **ModelContainer**: Configured in XiApp.swift with Habit schema, handles persistence
- **Habit Model**: Core entity with spaced repetition properties (intervals, success tracking)
- **ContentView**: Main interface using @Query for reactive habit display
- **NotificationManager**: Singleton managing notification scheduling, permissions, and responses
- **Notification Delegate**: Handles interactive notification responses in XiApp.swift

### Code Organization
- **Habit.swift**: SwiftData model with spaced repetition algorithms and computed properties
- **ContentView.swift**: Contains multiple view components (HabitRowView, HabitDetailView, AddHabitView)
- **NotificationManager.swift**: Centralized notification handling with @MainActor for UI updates
- **XiApp.swift**: App entry point with ModelContainer setup and notification delegate

## Development Guidelines

### SwiftData Integration
- Habit model uses @Model with persistent relationships and computed properties
- ModelContainer configured with Habit schema in app entry point
- Use @Query for reactive habit list updates in ContentView
- Access modelContext through @Environment for CRUD operations

### Notification System
- NotificationManager is a @MainActor singleton for thread safety
- Interactive notifications with YES/NO/LATER actions defined in setupNotificationCategories()
- Notification responses handled in NotificationDelegate within XiApp.swift
- Use persistent model IDs for notification-to-habit mapping

### Testing Frameworks
- **Unit Tests (XiTests/)**: Use Swift Testing with @Test macro and #expect() assertions
- **UI Tests (XiUITests/)**: Use XCTest with XCUIApplication for interface testing
- Test data operations with ModelContainer(inMemory: true) for isolation

## Current Implementation Status

### ✅ Completed Features
1. **Habit Data Model (Habit.swift)**
   - SwiftData model with spaced repetition fields
   - Properties: name, habitDescription, intervals, success tracking
   - Computed properties for success rate and streaks

2. **Habit Management UI (ContentView.swift)**
   - AddHabitView for creating habits with name input
   - HabitRowView showing success rate and next check-in
   - HabitDetailView with editable names and statistics
   - Add/edit/delete functionality

3. **Local Notification System (NotificationManager.swift)**
   - Permission handling and setup
   - Interactive notifications with Yes/No/Later actions
   - Test notifications (5-second delay for debugging)
   - Notification scheduling and cancellation

### 🚧 Next Steps (In Progress)
1. **Spaced Repetition Algorithm** - Core logic to adjust intervals based on responses (XiApp.swift:20-31)
2. **Notification Response Handling** - Process Yes/No/Later actions to update habits and reschedule
3. **Notification Scheduling Integration** - Connect spaced repetition calculations with NotificationManager
4. **Build Issues** - Resolve any compilation errors that may arise during development

### 🔧 Testing & Debugging
- Use "Test Notification (5s)" button in HabitDetailView for immediate testing
- "Check Pending" button shows all scheduled notifications in console
- "Schedule Normal" button schedules notification based on habit's nextNotificationDate
- Background the app to see notifications in iOS Simulator
- Check Xcode console for detailed notification scheduling logs with ✅/❌ indicators

### 🏗️ Implementation Notes
- **NotificationDelegate** in XiApp.swift has TODO comments for spaced repetition integration
- **Habit model** includes all necessary properties for spaced repetition (easeFactor, intervals)
- **Interactive notifications** are fully configured with three action buttons
- **Permission handling** is implemented with proper async/await patterns

## Development Workflow

### Code Update Guidelines
- Whenever you update the code in this project, you should automatically rebuild and relaunch it using the appropriate MCP.