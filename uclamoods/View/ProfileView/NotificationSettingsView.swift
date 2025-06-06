// NotificationSettingsView.swift
import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var userDataProvider: UserDataProvider
    @StateObject private var authService = AuthenticationService.shared // Assuming this service handles preference updates
    
    @State private var pushNotificationsEnabled: Bool = false
    @State private var notificationTime: Date = Date() // Represents local time in DatePicker
    
    // To store the original preferences to check for changes
    @State private var originalPushNotificationsEnabled: Bool = false
    @State private var originalNotificationHourPST: Int?
    @State private var originalNotificationMinutePST: Int?
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    private var pstTimeZone: TimeZone {
        TimeZone(identifier: "America/Los_Angeles")!
    }
    
    // Default notification time (1 PM PST)
    private var defaultPSTHour: Int = 13
    private var defaultPSTMinute: Int = 0
    
    private var hasFCMToken: Bool {
                if let token = userDataProvider.currentUser?.fcmToken, !token.isEmpty {
                    return true
                }
        return false
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Form {
                Section(header: Text("General").foregroundColor(.gray)) {
                    Toggle("Enable Push Notifications", isOn: $pushNotificationsEnabled)
                        .tint(.pink)
                        .onChange(of: pushNotificationsEnabled) { _, newValue in // ⓷ onChange modifier
                            if newValue == true {
                                // User toggled notifications ON
                                checkAndRequestPermissionsIfNeeded()
                            }
                            // If newValue is false, user is disabling.
                            // savePreferences() will handle saving this intent.
                        }
                }
                
                if pushNotificationsEnabled {
                    Section(header: Text("Scheduled Time (PST)").foregroundColor(.gray)) {
                        Text("Notifications will be sent daily at the selected Pacific Standard Time.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        DatePicker("Notify me at (PST)", selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(Color.white.opacity(0.8))
                            .colorScheme(.dark)
                            .onChange(of: notificationTime) { _, newDate in
                                // This date from DatePicker is in local time.
                                // We will convert its hour/minute to PST components when saving.
                                // For display, it's also fine, but the label clarifies PST.
                            }
                    }
                }
                
                if let msg = successMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let msg = errorMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Notification Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Button("Save") {
                            savePreferences()
                        }
                        .disabled(!hasChanges() || isLoading)
                    }
                }
            }
            .onAppear {
                loadPreferences()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func dateFrom(pstHour: Int?, pstMinute: Int?) -> Date {
        var components = Calendar.current.dateComponents(in: pstTimeZone, from: Date()) // Get current date in PST
        components.hour = pstHour ?? defaultPSTHour
        components.minute = pstMinute ?? defaultPSTMinute
        components.second = 0
        
        // Create a date in PST with the given hour/minute
        guard Calendar.current.date(from: components) != nil else {
            return Date() // Fallback
        }
        
        // Convert this PST date object back to the user's local timezone for the DatePicker
        // This ensures the DatePicker shows the "equivalent" local time that corresponds to the target PST time.
        // However, since the DatePicker itself uses local timezone, it might be simpler to just set the DatePicker's initial
        // components to the PST hour/minute, and interpret the selection as PST.
        // For simplicity, let's construct a Date object using the current system timezone but with hour/minute from PST.
        // The label "Notify me at (PST)" makes it clear what the time means.
        var localComponents = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        localComponents.hour = pstHour ?? defaultPSTHour
        localComponents.minute = pstMinute ?? defaultPSTMinute
        return Calendar.current.date(from: localComponents) ?? Date()
    }
    
    private func checkAndRequestPermissionsIfNeeded() {
        guard pushNotificationsEnabled else { return } // Only proceed if trying to enable
        
        if !hasFCMToken {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        // Permission not yet requested
                        self.requestNotificationPermission()
                    case .denied:
                        // Permission was denied previously
                        self.errorMessage = "Notification permissions are denied. Please enable them in your phone's Settings app."
                        self.pushNotificationsEnabled = false // Revert toggle
                        HapticFeedbackManager.shared.errorNotification()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.errorMessage = nil }
                    case .authorized, .provisional, .ephemeral:
                        // Permissions are already granted, but no FCM token found.
                        // This could mean the token registration failed or wasn't saved.
                        print("Permissions granted, but FCM token missing. Attempting to re-register for remote notifications.")
                        UIApplication.shared.registerForRemoteNotifications()
                        // You might want to inform the user if the token still doesn't arrive after a while.
                    @unknown default:
                        self.errorMessage = "Unknown notification authorization status."
                        self.pushNotificationsEnabled = false // Revert toggle
                        HapticFeedbackManager.shared.errorNotification()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.errorMessage = nil }
                    }
                }
            }
        } else {
            // User has an FCM token, implies permissions were already granted and handled.
            print("FCM token exists. No permission request needed from this view.")
        }
    }
    
    private func requestNotificationPermission() {
        // ⓹ Requesting actual permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error requesting permissions: \(error.localizedDescription)"
                    self.pushNotificationsEnabled = false // Revert toggle on error
                    HapticFeedbackManager.shared.errorNotification()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.errorMessage = nil }
                    return
                }
                
                if granted {
                    print("Notification permission granted by user.")
                    // Crucial step: After permission is granted, your app needs to register for remote notifications.
                    // This is typically done by calling:
                    UIApplication.shared.registerForRemoteNotifications()
                    // The AppDelegate (or equivalent) will then receive the device token,
                    // which is used by Firebase to generate an FCM token.
                    // That FCM token needs to be sent to your backend and saved with the user.
                    // This view initiates the process; the token handling is usually elsewhere.
                } else {
                    print("Notification permission denied by user.")
                    self.errorMessage = "Push notifications are required for this feature. You can enable them in Settings."
                    self.pushNotificationsEnabled = false // Revert toggle
                    HapticFeedbackManager.shared.errorNotification()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.errorMessage = nil }
                }
            }
        }
    }
    
    
    
    private func loadPreferences() {
        guard let preferences = userDataProvider.currentUser?.preferences else {
            pushNotificationsEnabled = true // Default to on as per your Mongoose schema
            notificationTime = dateFrom(pstHour: defaultPSTHour, pstMinute: defaultPSTMinute)
            
            originalPushNotificationsEnabled = pushNotificationsEnabled
            originalNotificationHourPST = defaultPSTHour
            originalNotificationMinutePST = defaultPSTMinute
            return
        }
        
        pushNotificationsEnabled = preferences.pushNotificationsEnabled ?? true
        let hourToLoad = preferences.notificationHourPST ?? defaultPSTHour
        let minuteToLoad = preferences.notificationMinutePST ?? defaultPSTMinute
        
        notificationTime = dateFrom(pstHour: hourToLoad, pstMinute: minuteToLoad)
        
        originalPushNotificationsEnabled = pushNotificationsEnabled
        originalNotificationHourPST = hourToLoad
        originalNotificationMinutePST = minuteToLoad
    }
    
    private func getPSTComponents(from localDate: Date) -> (hour: Int, minute: Int) {
        let calendar = Calendar.current
        // The DatePicker gives us a Date object. Its hour/minute components are in the user's local timezone.
        // We interpret these hour/minute values *as if* they are PST times because of the "(PST)" label.
        let localHour = calendar.component(.hour, from: localDate)
        let localMinute = calendar.component(.minute, from: localDate)
        return (localHour, localMinute)
    }
    
    
    private func hasChanges() -> Bool {
        if pushNotificationsEnabled != originalPushNotificationsEnabled {
            return true
        }
        if pushNotificationsEnabled {
            let currentPSTComponents = getPSTComponents(from: notificationTime)
            if currentPSTComponents.hour != originalNotificationHourPST || currentPSTComponents.minute != originalNotificationMinutePST {
                return true
            }
        }
        return false
    }
    
    private func savePreferences() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let pstComponents = getPSTComponents(from: notificationTime)
        let hourToSave = pstComponents.hour
        let minuteToSave = pstComponents.minute
        
        Task {
            do {
                // Call the new method in AuthenticationService
                try await authService.updateUserPreferences(
                    pushEnabled: pushNotificationsEnabled,
                    notificationHourPST: hourToSave,
                    notificationMinutePST: minuteToSave
                )
                
                // After successful backend update and profile refresh by authService,
                // the UserDataProvider will be updated automatically.
                // We just need to update the 'original' values here to reflect the new saved state
                // for the 'hasChanges()' logic.
                await MainActor.run {
                    originalPushNotificationsEnabled = pushNotificationsEnabled
                    originalNotificationHourPST = hourToSave
                    originalNotificationMinutePST = minuteToSave
                    
                    isLoading = false
                    successMessage = "Preferences saved!"
                    HapticFeedbackManager.shared.successNotification() // Added success haptic
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription // Display the specific error from authService
                    HapticFeedbackManager.shared.errorNotification() // Added error haptic
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // Keep error message longer
                        self.errorMessage = nil
                    }
                }
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
                .environmentObject(UserDataProvider.shared) // Use shared for preview
        }
        .preferredColorScheme(.dark)
    }
}
