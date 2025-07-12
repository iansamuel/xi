# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS app built with SwiftUI and SwiftData. The project is a simple data management app that demonstrates basic CRUD operations with SwiftData models. It includes remote notification capabilities and uses the new Swift Testing framework.

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