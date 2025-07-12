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
    @State private var showingAddHabit = false

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
                    Button(action: { showingAddHabit = true }) {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Habits")
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView { habitName in
                    addHabit(name: habitName)
                }
            }
        } detail: {
            Text("Select a habit")
        }
    }

    private func addHabit(name: String) {
        withAnimation {
            let newHabit = Habit(name: name, habitDescription: "")
            modelContext.insert(newHabit)
            
            // Schedule notification for the new habit
            Task {
                await NotificationManager.shared.checkPermissionStatus()
                if NotificationManager.shared.hasPermission {
                    NotificationManager.shared.scheduleHabitNotification(for: newHabit)
                }
            }
        }
    }

    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let habit = habits[index]
                NotificationManager.shared.cancelNotification(for: habit)
                modelContext.delete(habit)
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
    @State private var isEditingName = false
    @State private var editedName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditingName {
                TextField("Habit name", text: $editedName)
                    .font(.largeTitle)
                    .bold()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        habit.name = editedName
                        isEditingName = false
                    }
            } else {
                Text(habit.name)
                    .font(.largeTitle)
                    .bold()
                    .onTapGesture {
                        editedName = habit.name
                        isEditingName = true
                    }
            }
            
            if !habit.habitDescription.isEmpty {
                Text(habit.habitDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Success Rate: \(habit.successRate, specifier: "%.1%")")
                Text("Total Attempts: \(habit.totalAttempts)")
                Text("Successful: \(habit.successfulAttempts)")
                Text("Current Interval: \(formatInterval(habit.currentInterval))")
                Text("Next Check-in: \(habit.nextNotificationDate, style: .relative)")
                
                Button("Test Notification") {
                    NotificationManager.shared.scheduleHabitNotification(for: habit)
                }
                .buttonStyle(.bordered)
            }
            .font(.body)
            
            Spacer()
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    editedName = habit.name
                    isEditingName = true
                }
            }
        }
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

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var habitName = ""
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Habit name", text: $habitName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                
                Text("Enter a name for your new habit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSave(habitName.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
