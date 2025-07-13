//
//  ContentView.swift
//  Xi
//
//  Created by Ian Samuel on 7/12/25.
//

import SwiftUI
import SwiftData

// Popular emoji options for habits
let popularEmojis = ["🧘", "🏃", "📚", "💧", "🧘‍♀️", "🚴", "🍎", "💪", "🎯", "✍️", "🎨", "🎵", "🌿", "☕"]

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.988, blue: 0.98)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chinese Character Header
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Text("习")
                                .font(.custom("Outfit", size: 28).weight(.bold))
                                .foregroundColor(Color(red: 0.157, green: 0.129, blue: 0.106))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 6)
                        
                        HStack {
                            Text("Your Habits")
                                .font(.custom("Outfit", size: 22))
                                .foregroundColor(Color(red: 0.157, green: 0.129, blue: 0.106))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                    }
                    
                    // Habits List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(habits) { habit in
                                NavigationLink(destination: HabitDetailView(habit: habit)) {
                                    HabitCardView(habit: habit)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    
                    Spacer()
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddHabit = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .foregroundColor(Color(red: 0.157, green: 0.129, blue: 0.106))
                                    .font(.system(size: 17, weight: .medium))
                                Text("Add Habit")
                                    .foregroundColor(Color(red: 0.157, green: 0.129, blue: 0.106))
                                    .font(.custom("Outfit", size: 17).weight(.medium))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color(red: 1.0, green: 0.5, blue: 0.0))
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.08), radius: 3.5, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView { habitName in
                    addHabit(name: habitName)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(habits: habits)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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

struct HabitCardView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.494, green: 0.322, blue: 0.145).opacity(0.09))
                        .frame(width: 40, height: 40)
                    
                    Text(habit.selectedIcon)
                        .font(.system(size: 20))
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.custom("Outfit", size: 17))
                    .foregroundColor(Color(red: 0.157, green: 0.129, blue: 0.106))
                
                Text(habit.habitDescription.isEmpty ? "Daily habit" : habit.habitDescription)
                    .font(.custom("Outfit", size: 15))
                    .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .padding(.top, 8)
        }
        .background(Color(red: 0.494, green: 0.322, blue: 0.145).opacity(0.05))
        .cornerRadius(12)
    }
    
}

struct HabitDetailView: View {
    let habit: Habit
    @State private var editedName = ""
    @State private var showingEmojiPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.996, green: 0.988, blue: 0.984)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Habit Name Field
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "house")
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                                .font(.system(size: 18))
                            
                            TextField("Habit Name", text: $editedName)
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(.black)
                                .onSubmit {
                                    if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        habit.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    }
                                }
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color(red: 0.447, green: 0.322, blue: 0.192).opacity(0.09))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    
                    // Icon Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Emoji Picker Button
                            Button(action: { showingEmojiPicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 16))
                                    Text("Pick Emoji")
                                        .font(.custom("Plus Jakarta Sans", size: 13).weight(.medium))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.996, green: 0.988, blue: 0.984))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 0.431, green: 0.361, blue: 0.286).opacity(0.2), lineWidth: 0.5)
                                )
                                .cornerRadius(20)
                            }
                            
                            // Currently selected emoji (always shown right after Pick Emoji)
                            EmojiChipView(emoji: habit.selectedIcon, isSelected: true) {
                                // Tapping the selected emoji also opens the picker
                                showingEmojiPicker = true
                            }
                            
                            // Pre-defined emoji options (excluding the currently selected one)
                            ForEach(popularEmojis.filter { $0 != habit.selectedIcon }, id: \.self) { emoji in
                                EmojiChipView(emoji: emoji, isSelected: false) {
                                    habit.selectedIcon = emoji
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // Frequency Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Daily", "Weekly", "Monthly", "Custom"], id: \.self) { frequency in
                                FrequencyChipView(
                                    frequency: frequency,
                                    isSelected: habit.frequency == frequency
                                ) {
                                    habit.frequency = frequency
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // Success Rate Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Success Rate")
                            .font(.custom("Plus Jakarta Sans", size: 18).weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                                .font(.system(size: 18))
                            
                            Text("\(habit.successRate, specifier: "%.0f")%")
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color(red: 0.447, green: 0.322, blue: 0.192).opacity(0.09))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Next Reminder Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next Scheduled Reminder")
                            .font(.custom("Plus Jakarta Sans", size: 18).weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "bell")
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                                .font(.system(size: 18))
                            
                            Text(formatNextReminder(habit.nextNotificationDate))
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color(red: 0.447, green: 0.322, blue: 0.192).opacity(0.09))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedName = habit.name
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(selectedIcon: Binding(
                get: { habit.selectedIcon },
                set: { habit.selectedIcon = $0 }
            ))
        }
    }
    
    private func formatNextReminder(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct EmojiChipView: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(isSelected ? Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.3) : Color(red: 0.996, green: 0.988, blue: 0.984))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(isSelected ? Color(red: 1.0, green: 0.5, blue: 0.0) : Color(red: 0.431, green: 0.361, blue: 0.286).opacity(0.2), lineWidth: isSelected ? 2 : 0.5)
                )
                .cornerRadius(22)
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    
    let emojiCategories = [
        ("Activities", ["🧘", "🏃", "🚴", "🏊", "🧘‍♀️", "🏋️", "🤸", "🏌️", "🎾", "⚽", "🏀", "🏈"]),
        ("Food & Drink", ["🍎", "🥗", "🥤", "☕", "🧊", "🍌", "🥕", "🥛", "🧋", "🫖", "🍊", "🥑"]),
        ("Learning", ["📚", "✍️", "🎨", "🎵", "📝", "💻", "🔬", "📊", "🎯", "🧮", "📐", "🔍"]),
        ("Health", ["💪", "🧠", "❤️", "🦷", "👁️", "🩺", "💊", "🧴", "🧼", "🏥", "🌡️", "⚕️"]),
        ("Nature", ["🌿", "🌱", "🌳", "🌸", "🌞", "🌙", "⭐", "🌈", "🌊", "🏔️", "🌲", "🍃"]),
        ("Objects", ["📱", "💡", "🔑", "⏰", "📅", "🎁", "🧩", "🎲", "🔮", "💎", "🏆", "🎖️"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(emojiCategories, id: \.0) { category, emojis in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category)
                                .font(.custom("Plus Jakarta Sans", size: 18).weight(.bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button(action: {
                                        selectedIcon = emoji
                                        dismiss()
                                    }) {
                                        Text(emoji)
                                            .font(.system(size: 32))
                                            .frame(width: 50, height: 50)
                                            .background(selectedIcon == emoji ? Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.3) : Color.clear)
                                            .cornerRadius(25)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(selectedIcon == emoji ? Color(red: 1.0, green: 0.5, blue: 0.0) : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Pick an Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                }
            }
        }
    }
}

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var habitName = ""
    @State private var selectedFrequency = "Daily"
    let onSave: (String) -> Void
    
    let frequencies = ["Daily", "Weekly", "Monthly", "Custom"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.988, blue: 0.98)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Habit Name Field
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "scissors")
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                                .font(.system(size: 18))
                            
                            TextField("Habit Name", text: $habitName)
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color(red: 0.447, green: 0.322, blue: 0.192).opacity(0.09))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Frequency Field
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                                .font(.system(size: 18))
                            
                            Text("Frequency")
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color(red: 0.447, green: 0.322, blue: 0.192).opacity(0.09))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    // Frequency Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(frequencies, id: \.self) { frequency in
                                FrequencyChipView(
                                    frequency: frequency,
                                    isSelected: selectedFrequency == frequency
                                ) {
                                    selectedFrequency = frequency
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Add Habit Button
                    Button(action: {
                        if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSave(habitName.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                                .font(.system(size: 17, weight: .medium))
                            Text("Add Habit")
                                .foregroundColor(.black)
                                .font(.custom("Plus Jakarta Sans", size: 17).weight(.medium))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(red: 1.0, green: 0.5, blue: 0.0))
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.08), radius: 3.5, x: 0, y: 2)
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
                }
            }
        }
    }
}

struct FrequencyChipView: View {
    let frequency: String
    let isSelected: Bool
    let action: () -> Void
    
    private var iconName: String {
        switch frequency {
        case "Daily": return "sun.max"
        case "Weekly": return "calendar"
        case "Monthly": return "moon"
        case "Custom": return "gearshape"
        default: return "circle"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(frequency)
                    .font(.custom("Plus Jakarta Sans", size: 13).weight(.medium))
                    .foregroundColor(isSelected ? .white : .black)
                
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color(red: 0.18, green: 0.129, blue: 0.078).opacity(0.62))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isSelected ? Color(red: 1.0, green: 0.5, blue: 0.0) : Color(red: 0.447, green: 0.322, blue: 0.192).opacity(0.09))
            .cornerRadius(20)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]
    
    var body: some View {
        NavigationView {
            List {
                Section("Notification Testing") {
                    ForEach(habits) { habit in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(habit.name)
                                .font(.headline)
                            
                            HStack {
                                Button("Test (5s)") {
                                    NotificationManager.shared.scheduleTestNotification(for: habit, delay: 5)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Schedule") {
                                    NotificationManager.shared.scheduleHabitNotification(for: habit)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("Check Pending Notifications") {
                        NotificationManager.shared.printPendingNotifications()
                    }
                    .buttonStyle(.bordered)
                }
                
                Section("Debug Info") {
                    Text("Total Habits: \(habits.count)")
                    Text("Active Habits: \(habits.filter { $0.isActive }.count)")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
