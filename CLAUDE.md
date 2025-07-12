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
│   ├── XiApp.swift           # App entry point with SwiftData container
│   ├── ContentView.swift     # Main UI with NavigationSplitView
│   ├── Item.swift           # SwiftData model
│   ├── Assets.xcassets/     # App icons and assets
│   ├── Info.plist          # Remote notification configuration
│   └── Xi.entitlements     # App entitlements
├── XiTests/                 # Unit tests using Swift Testing
└── XiUITests/              # UI tests
```

### Key Technologies
- **SwiftUI**: For declarative UI with NavigationSplitView
- **SwiftData**: For data persistence and modeling (@Model, @Query)
- **Swift Testing**: New testing framework (not XCTest)
- **Remote Notifications**: Configured in Info.plist

### Data Flow
- SwiftData ModelContainer is configured in XiApp.swift with the Item schema
- ContentView uses @Query to reactively display items from the data store
- @Environment(\.modelContext) provides access to data operations
- Items are simple timestamp-based entities demonstrating basic CRUD

### Code Organization
- Keep SwiftData models simple and focused (like Item.swift)
- Use @Query for reactive data fetching in views
- Leverage SwiftUI's @Environment for dependency injection
- Follow SwiftData patterns for model relationships when scaling

## Development Guidelines

### SwiftData Best Practices
- Use @Model macro for data models
- Configure ModelContainer in the app entry point
- Use @Query for reactive data access in views
- Access modelContext through @Environment for data operations

### Testing
- Use Swift Testing framework with @Test macro
- Import @testable import Xi for internal access
- Place tests in XiTests/ and XiUITests/ targets
- Test data operations by mocking ModelContainer with inMemory: true

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
1. **Build Issues** - Some compilation errors need to be resolved
2. **Spaced Repetition Algorithm** - Core logic to adjust intervals based on responses
3. **Notification Response Handling** - Process Yes/No/Later actions to update habits
4. **Notification Scheduling Integration** - Connect spaced repetition with notification timing

### 🔧 Testing & Debugging
- Use "Test Notification (5s)" button in habit detail view
- Check Xcode console for notification scheduling logs
- "Check Pending" button shows scheduled notifications
- Background app to see notifications in simulator