//
//  ContentView.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(habits) { habit in
                    NavigationLink {
                        HabitDetailView(habit: habit)
                    } label: {
                        HabitRowView(habit: habit)
                    }
                }
                .onDelete(perform: deleteHabits)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addHabit) {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Habits")
        } detail: {
            Text("Select a habit")
        }
    }

    private func addHabit() {
        withAnimation {
            let newHabit = Habit(name: "New Habit", description: "")
            modelContext.insert(newHabit)
        }
    }

    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(habits[index])
            }
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(habit.name)
                .font(.headline)
            Text("Success rate: \(habit.successRate, specifier: "%.1%")")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Next check-in: \(habit.nextNotificationDate, style: .relative)")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
}

struct HabitDetailView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(habit.name)
                .font(.largeTitle)
                .bold()
            
            if !habit.description.isEmpty {
                Text(habit.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Group {
                Text("Success Rate: \(habit.successRate, specifier: "%.1%")")
                Text("Total Attempts: \(habit.totalAttempts)")
                Text("Successful: \(habit.successfulAttempts)")
                Text("Current Interval: \(formatInterval(habit.currentInterval))")
                Text("Next Check-in: \(habit.nextNotificationDate, style: .relative)")
            }
            .font(.body)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
