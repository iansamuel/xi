import SwiftUI
import SwiftData // Import SwiftData

struct HabitConfirmationView: View {
    @Bindable var habit: Habit // Non-optional binding
    @EnvironmentObject var notificationManager: NotificationManager // EnvironmentObject
    
    var body: some View {
        ZStack {
            Color("BackgroundColor") // Background color #fffbfa
                .edgesIgnoringSafeArea(.all)

            VStack {
                // MARK: - Header Navigation Bar
                VStack(spacing: 0) {
                    // Status Bar
                    HStack {
                        Text("12:45")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                            .padding(.leading, 24)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "signal.square.fill") // Placeholder for Signal
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 23.5, height: 14)
                                .foregroundColor(Color("PrimaryTextColor"))
                            Image(systemName: "wifi") // Placeholder for Wifi
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 17, height: 13)
                                .foregroundColor(Color("PrimaryTextColor"))
                            Image(systemName: "battery.100") // Placeholder for Battery
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 23.5, height: 11)
                                .foregroundColor(Color("PrimaryTextColor"))
                        }
                        .padding(.trailing, 24)
                    }
                    .frame(height: 56) // Status bar height

                    // Navigation Bar
                    HStack {
                        Text("Habit Tracker")
                            .font(.custom("PlusJakartaSans-Bold", size: 17)) // Assuming custom font
                            .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                            .kerning(-0.34)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    .frame(height: 44) // Navigation bar height
                }

                // MARK: - Main Content
                VStack(alignment: .leading, spacing: 0) {
                    // Onboarding Question and Text Field with Icon 01
                    VStack(alignment: .leading, spacing: 0) {
                        // Table Title
                        VStack(alignment: .leading, spacing: 0) {
                            // Table Header
                            HStack {
                                Text(habit.name) // Use habit.name
                                    .font(.custom("PlusJakartaSans-Bold", size: 18))
                                    .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                                    .kerning(-0.36)
                                    .padding(.leading, 18)
                                Spacer()
                            }
                            .padding(.top, 28) // pt-7
                            .padding(.bottom, 2) // pb-0.5
                        }

                        // Subtitle
                        HStack {
                            Text(habit.habitDescription.isEmpty ? "Did you do your habit: \(habit.name)?" : habit.habitDescription) // Use habit.habitDescription
                                .font(.custom("PlusJakartaSans-Regular", size: 17))
                                .foregroundColor(Color("SecondaryTextColor")) // rgba(46,24,20,0.62)
                                .lineLimit(nil) // Allow multiple lines
                                .padding(.leading, 18)
                            Spacer()
                        }
                        .padding(.vertical, 4) // py-1

                        // Text Field with Icon
                        HStack {
                            Spacer()
                            HStack(spacing: 8) { // gap-2
                                Image(systemName: "drop.fill") // Placeholder for Drop icon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(Color("SecondaryTextColor")) // rgba(46,24,20,0.62)

                                Text("Frequency: \(habit.frequency)") // Use habit.frequency
                                    .font(.custom("PlusJakartaSans-Regular", size: 17))
                                    .foregroundColor(Color("SecondaryTextColor")) // rgba(46,24,20,0.62)
                                Spacer()
                            }
                            .padding(.horizontal, 13) // px-13
                            .padding(.vertical, 13.5) // py-13.5
                            .background(Color("ButtonSecondaryColor")) // rgba(126,52,37,0.09)
                            .cornerRadius(20)
                            .padding(.horizontal, 18) // px-18
                            Spacer()
                        }
                        .padding(.vertical, 8) // py-2
                    }
                    .padding(.bottom, 20) // Add some space between this section and buttons

                    Spacer() // Pushes content to top for now

                    // MARK: - Triple Buttons Vertical Large with Icon
                    VStack(spacing: 16) { // gap-4
                        // Yes, I Remembered Button
                        Button(action: {
                            habit.recordSuccess()
                            notificationManager.scheduleHabitNotification(for: habit)
                            notificationManager.habitToConfirm = nil // Dismiss action
                        }) {
                            HStack(spacing: 8) { // gap-2
                                Image(systemName: "checkmark.circle.fill") // Placeholder for Checkmark
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                                Text("Yes, I Remembered")
                                    .font(.custom("PlusJakartaSans-Regular", size: 17))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // py-3.5
                            .background(Color("ButtonPrimaryColor")) // #7e3425
                            .cornerRadius(48)
                        }

                        // No, I Forgot Button
                        Button(action: {
                            habit.recordFailure()
                            notificationManager.scheduleHabitNotification(for: habit)
                            notificationManager.habitToConfirm = nil // Dismiss action
                        }) {
                            HStack(spacing: 8) { // gap-2
                                Image(systemName: "compass.circle.fill") // Placeholder for Compass
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                                Text("No, I Forgot")
                                    .font(.custom("PlusJakartaSans-Regular", size: 17))
                                    .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // py-3.5
                            .background(Color("ButtonSecondaryColor")) // rgba(126,52,37,0.09)
                            .cornerRadius(48)
                        }

                        // Hasn't Come Up Yet Button
                        Button(action: {
                            habit.recordLater()
                            notificationManager.scheduleHabitNotification(for: habit)
                            notificationManager.habitToConfirm = nil // Dismiss action
                        }) {
                            HStack(spacing: 8) { // gap-2
                                Image(systemName: "clock.fill") // Placeholder for Clock
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                                Text("Hasn't Come Up Yet")
                                    .font(.custom("PlusJakartaSans-Regular", size: 17))
                                    .foregroundColor(Color("PrimaryTextColor")) // #281d1b
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // py-3.5
                            .background(Color.clear)
                            .cornerRadius(48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 48)
                                    .stroke(Color("ButtonBorderColor"), lineWidth: 0.5) // rgba(110,79,73,0.2)
                            )
                        }
                    }
                    .padding(.horizontal, 16) // p-16
                    .padding(.bottom, 16) // Add padding to the bottom of the buttons
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Align content to top leading
                .padding(.top, 0) // No top padding for main content, it's handled by header
                Spacer() // Pushes content to top for now

                // MARK: - Bottom Bar
                VStack {
                    Capsule()
                        .fill(Color("ButtonSecondaryColor")) // rgba(126,53,37,0.09)
                        .frame(width: 120, height: 4)
                        .padding(.bottom, 8)
                }
                .frame(height: 32) // Gesture Indicator Bar height
            }
        }
    }
}

struct HabitConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy habit for preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, configurations: config)
        let dummyHabit = Habit(name: "Drink Water", habitDescription: "Stay hydrated throughout the day.")
        dummyHabit.frequency = "Daily"
        container.mainContext.insert(dummyHabit)
        
        return HabitConfirmationView(habit: dummyHabit)
            .environmentObject(NotificationManager.shared)
            .modelContainer(container)
    }
}