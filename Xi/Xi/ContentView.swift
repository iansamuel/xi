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
    @EnvironmentObject var notificationManager: NotificationManager // Add EnvironmentObject
    @Query private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chinese Character Header
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Text("习")
                                .font(.custom("Outfit", size: 28).weight(.bold))
                                .foregroundColor(Color("PrimaryTextColor"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 6)
                        
                        HStack {
                            Text("Your Habits")
                                .font(.custom("Outfit", size: 22))
                                .foregroundColor(Color("PrimaryTextColor"))
                            Spacer()
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("SecondaryTextColor"))
                            }
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
                                    .foregroundColor(Color("PrimaryTextColor"))
                                    .font(.system(size: 17, weight: .medium))
                                Text("Add Habit")
                                    .foregroundColor(Color("PrimaryTextColor"))
                                    .font(.custom("Outfit", size: 17).weight(.medium))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color("AccentColor"))
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
                AddHabitView { habitName, frequency in
                    addHabit(name: habitName, frequency: frequency)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(habits: habits)
            }
            .sheet(item: $notificationManager.habitToConfirm) { habit in // Use .sheet(item:) for optional binding
                HabitConfirmationView(habit: habit) // Pass the habit
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Check for overdue habits when the view appears
            notificationManager.checkForOverdueHabits(habits)
        }
        .onChange(of: habits) { _, newHabits in
            // Also check when habits list changes (like when app returns to foreground)
            notificationManager.checkForOverdueHabits(newHabits)
        }
    }

    private func addHabit(name: String, frequency: String) {
        withAnimation {
            let newHabit = Habit(name: name, habitDescription: "")
            newHabit.frequency = frequency
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
                        .fill(Color("CardBackgroundColor").opacity(0.09))
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
                    .foregroundColor(Color("PrimaryTextColor"))
                
                Text(habit.frequency)
                    .font(.custom("Outfit", size: 15))
                    .foregroundColor(Color("SecondaryTextColor"))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .padding(.top, 8)
        }
        .background(Color("CardBackgroundColor").opacity(0.05))
        .cornerRadius(12)
    }
    
}

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @State private var editedName = ""
    @State private var showingEmojiPicker = false
    @State private var initialSelectedIcon = "" // Track initial emoji for stable ordering
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext // Add this line
    
    // Computed property for stable emoji ordering
    private var orderedEmojis: [String] {
        var result: [String] = []
        
        // First, add the currently selected emoji if it's not in popularEmojis
        // This handles custom emojis from the picker
        if !habit.selectedIcon.isEmpty && !popularEmojis.contains(habit.selectedIcon) {
            result.append(habit.selectedIcon)
        }
        
        // Then, add the initial selected emoji if it exists in popularEmojis
        // This ensures the originally selected popular emoji appears first
        if !initialSelectedIcon.isEmpty && popularEmojis.contains(initialSelectedIcon) {
            result.append(initialSelectedIcon)
        }
        
        // Finally, add all other popular emojis in their original order
        for emoji in popularEmojis {
            if emoji != initialSelectedIcon {
                result.append(emoji)
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Habit Name Field
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "house")
                                .foregroundColor(Color("SecondaryTextColor"))
                                .font(.system(size: 18))
                            
                            TextField("Habit Name", text: $editedName)
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(Color("PrimaryTextColor"))
                                .onSubmit {
                                    if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        habit.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    }
                                }
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color("TextFieldBackgroundColor"))
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
                                .foregroundColor(Color("PrimaryTextColor"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color("BackgroundColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color("ButtonBorderColor"), lineWidth: 0.5)
                                )
                                .cornerRadius(20)
                            }
                            
                            // Show emojis in stable order with current selection highlighted
                            ForEach(orderedEmojis, id: \.self) { emoji in
                                EmojiChipView(emoji: emoji, isSelected: emoji == habit.selectedIcon) {
                                    if emoji == habit.selectedIcon {
                                        // Tapping the selected emoji opens the picker
                                        showingEmojiPicker = true
                                    } else {
                                        // Tapping other emojis selects them
                                        habit.selectedIcon = emoji
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // Frequency Chips
                    HStack(spacing: 8) {
                        ForEach(["Daily", "Weekly", "Monthly"], id: \.self) { frequency in
                            FrequencyChipView(
                                frequency: frequency,
                                isSelected: habit.frequency == frequency
                            ) {
                                habit.frequency = frequency
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Success Rate Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Success Rate")
                            .font(.custom("Plus Jakarta Sans", size: 18).weight(.bold))
                            .foregroundColor(Color("PrimaryTextColor"))
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(Color("SecondaryTextColor"))
                                .font(.system(size: 18))
                            
                            Text("\(habit.successRate, specifier: "%.0f")%")
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(Color("SecondaryTextColor"))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color("TextFieldBackgroundColor"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Next Reminder Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next Scheduled Reminder")
                            .font(.custom("Plus Jakarta Sans", size: 18).weight(.bold))
                            .foregroundColor(Color("PrimaryTextColor"))
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "bell")
                                .foregroundColor(Color("SecondaryTextColor"))
                                .font(.system(size: 18))
                            
                            DatePicker(
                                "",
                                selection: $habit.nextNotificationDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .font(.custom("Plus Jakarta Sans", size: 17))
                            .foregroundColor(Color("PrimaryTextColor"))
                            .onChange(of: habit.nextNotificationDate) { oldValue, newValue in
                                NotificationManager.shared.scheduleHabitNotification(for: habit)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color("TextFieldBackgroundColor"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)

                    // Delete Habit Button
                    Button(action: {
                        deleteHabit()
                    }) {
                        Text("Delete Habit")
                            .font(.custom("Plus Jakarta Sans", size: 17).weight(.medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedName = habit.name
            initialSelectedIcon = habit.selectedIcon // Capture initial emoji for stable ordering
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(selectedIcon: Binding(
                get: { habit.selectedIcon },
                set: { habit.selectedIcon = $0 }
            ))
        }
    }

    private func deleteHabit() {
        withAnimation {
            NotificationManager.shared.cancelNotification(for: habit)
            modelContext.delete(habit)
            dismiss()
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
                .background(isSelected ? Color("AccentColor").opacity(0.3) : Color("BackgroundColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(isSelected ? Color("AccentColor") : Color("ButtonBorderColor"), lineWidth: 2)
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
                                .foregroundColor(Color("PrimaryTextColor"))
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
                                            .background(selectedIcon == emoji ? Color("AccentColor").opacity(0.3) : Color.clear)
                                            .cornerRadius(25)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(selectedIcon == emoji ? Color("AccentColor") : Color.clear, lineWidth: 2)
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
                    .foregroundColor(Color("AccentColor"))
                }
            }
        }
    }
}

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var habitName = ""
    @State private var selectedFrequency = "Daily"
    let onSave: (String, String) -> Void
    
    let frequencies = ["Daily", "Weekly", "Monthly"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Habit Name Field
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "scissors")
                                .foregroundColor(Color("SecondaryTextColor"))
                                .font(.system(size: 18))
                            
                            TextField("Habit Name", text: $habitName)
                                .font(.custom("Plus Jakarta Sans", size: 17))
                                .foregroundColor(Color("PrimaryTextColor"))
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13.5)
                        .background(Color("TextFieldBackgroundColor"))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Frequency Chips
                    HStack(spacing: 8) {
                        ForEach(frequencies, id: \.self) { frequency in
                            FrequencyChipView(
                                frequency: frequency,
                                isSelected: selectedFrequency == frequency
                            ) {
                                selectedFrequency = frequency
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Add Habit Button
                    Button(action: {
                        if !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSave(habitName.trimmingCharacters(in: .whitespacesAndNewlines), selectedFrequency)
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .foregroundColor(Color("PrimaryTextColor"))
                                .font(.system(size: 17, weight: .medium))
                            Text("Add Habit")
                                .foregroundColor(Color("PrimaryTextColor"))
                                .font(.custom("Plus Jakarta Sans", size: 17).weight(.medium))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color("AccentColor"))
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
                    .foregroundColor(Color("SecondaryTextColor"))
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
                Spacer()
                Text(frequency)
                    .font(.custom("Plus Jakarta Sans", size: 13).weight(.medium))
                    .foregroundColor(isSelected ? .white : Color("PrimaryTextColor"))
                
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color("SecondaryTextColor"))
                Spacer()
            }
            .padding(.vertical, 5)
            .background(isSelected ? Color("AccentColor") : Color("TextFieldBackgroundColor"))
            .cornerRadius(20)
            .frame(maxWidth: .infinity) // Ensure the internal HStack expands
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