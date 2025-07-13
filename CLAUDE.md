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

### ✅ Completed Implementation
1. **Spaced Repetition Algorithm** - Complete adaptive interval system (Habit.swift:59-87)
2. **Notification Response Handling** - Full Yes/No/Later processing with habit updates (XiApp.swift:30-79)
3. **Settings UI** - Gear icon with testing functions moved from habit details
4. **Custom App Icon** - McLaren orange icon with dark/tinted variants
5. **GitHub Repository** - Complete project with README at https://github.com/iansamuel/xi

### 🔧 Testing & Debugging
- Use "Test Notification (5s)" button in HabitDetailView for immediate testing
- "Check Pending" button shows all scheduled notifications in console
- "Schedule Normal" button schedules notification based on habit's nextNotificationDate
- Background the app to see notifications in iOS Simulator
- Check Xcode console for detailed notification scheduling logs with ✅/❌ indicators

### 🏗️ Implementation Notes
- **Complete spaced repetition system** with success/failure/later logic fully implemented
- **Interactive notifications** with proper ModelContainer injection pattern (fixed casting warnings)
- **Local storage only** - CloudKit/remote notifications removed for free developer accounts
- **Deployed and tested** on both simulator and physical iPhone device

## Development Workflow

### Git Best Practices
**CRITICAL**: Always maintain proper git commit history throughout development sessions.
- Commit changes after each significant feature or fix is completed
- Use descriptive commit messages that explain what was accomplished
- Don't accumulate changes across multiple features before committing
- Follow the pattern: implement feature → test → commit → move to next feature
- Example commit workflow:
  ```bash
  git add .
  git commit -m "Add emoji picker functionality with categorized selection"
  ```

### Figma-to-SwiftUI Integration Workflow
When working with Figma designs using the MCP server:
1. **Node Selection**: Help user understand Figma "nodes" and selection process
2. **Code Generation**: Use `mcp__figma-dev-mode-mcp-server__get_code` to generate SwiftUI
3. **Image Context**: Always call `mcp__figma-dev-mode-mcp-server__get_image` after code generation
4. **Iterative Design**: Expect multiple rounds of refinement based on visual feedback
5. **Design Splitting**: Be prepared to logically split single Figma designs into multiple SwiftUI views
6. **Font Integration**: Pay attention to custom fonts (Plus Jakarta Sans, Outfit) and implement properly

### SwiftData Schema Migration Handling
When adding properties to SwiftData models:
- **Expect Migration Issues**: Adding new properties can cause ModelContainer creation failures
- **Error Handling Pattern**: Implement try-catch with database recreation fallback in XiApp.swift:
  ```swift
  do {
      sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
  } catch {
      // Recreate database for schema changes
      let url = URL.applicationSupportDirectory.appending(path: "default.store")
      if FileManager.default.fileExists(atPath: url.path) {
          try FileManager.default.removeItem(at: url)
      }
      sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
  }
  ```
- **Default Values**: Always provide sensible defaults for new properties in model initializers

### Iterative Development Process
- **User Feedback Integration**: Expect multiple rounds of UI/UX refinement
- **Layout Debugging**: Be prepared to fix layout issues (ScrollView nesting, floating elements)
- **Visual Consistency**: Apply design changes consistently across all screens
- **Immediate Testing**: Build and launch after each significant change for visual verification

### Code Update Guidelines
- Whenever you update the code in this project, you should automatically rebuild and relaunch it using the appropriate MCP
- Test functionality immediately after implementation
- Address any build errors or warnings before proceeding to next task

## Assistant Improvement Guidelines

### Session Management
- **Maintain Context**: Keep track of what has been implemented throughout the session
- **Todo Management**: Use TodoWrite tool proactively to track progress and pending tasks
- **Git Hygiene**: Commit changes regularly, not just at the end of sessions
- **Error Recovery**: When encountering crashes or build issues, methodically debug and document solutions

### Communication Best Practices
- **Visual Verification**: Always build and test UI changes in simulator for layout confirmation
- **User Collaboration**: Help users understand technical concepts (nodes, schema migration, etc.) when needed
- **Iterative Refinement**: Expect and plan for multiple rounds of polish and refinement
- **Proactive Problem Solving**: Anticipate common issues (layout problems, binding errors, migration crashes)

### Technical Excellence
- **Error Handling**: Implement robust error handling patterns, especially for data layer changes
- **Code Quality**: Follow existing code conventions and maintain consistency
- **Testing Integration**: Use available testing infrastructure for verification
- **Performance Awareness**: Consider implications of UI changes on app performance