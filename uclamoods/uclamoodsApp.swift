import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
struct uclamoodsApp: App {
    @StateObject private var userDataProvider = UserDataProvider.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    init() {
        // Initialize authentication service early
        configureAuthentication()
    }
    
    var body: some Scene {
        WindowGroup {
            MoodAppContainer()
                .environmentObject(userDataProvider)
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAuthentication() {
        // This ensures auth service is initialized and loads stored tokens
        _ = AuthenticationService.shared
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // Configure Firebase
        print("[AppDelegate] Firebase configured.")

        // Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Request notification permissions
        requestNotificationAuthorization(application: application)

        return true
    }

    func requestNotificationAuthorization(application: UIApplication) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("[AppDelegate] Notification permission granted: \(granted)")
            if let error = error {
                print("[AppDelegate] Error requesting notification authorization: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - APNS Token Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let apnsToken = tokenParts.joined()
        print("[AppDelegate] APNS device token: \(apnsToken)")
        // Set APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - FCM Token Registration (MessagingDelegate)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("[AppDelegate] FCM token is nil.")
            return
        }
        print("[AppDelegate] Firebase registration token (FCM token): \(token)")

        // Send this token to your server
        // You might want to store it locally and send it only when it changes or when the user logs in.
        AuthenticationService.shared.sendFCMTokenToBackend(fcmToken: token)

        // TODO: Persist this token locally if needed, or send to server
        // Example: UserDefaults.standard.set(token, forKey: "fcmToken")
    }

    // MARK: - Handling Foreground Notifications (UNUserNotificationCenterDelegate)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("[AppDelegate] Will present notification in foreground: \(userInfo)")

        // Show the notification in foreground
        // You can customize this: .banner, .list, .sound, .badge
        completionHandler([[.list, .banner, .sound, .badge]])
    }

    // MARK: - Handling Tapped Notifications (UNUserNotificationCenterDelegate)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("[AppDelegate] Did receive notification response (user tapped): \(userInfo)")

        // Handle the tapped notification, e.g., navigate to a specific screen
        // if let screenToOpen = userInfo["screenToOpen"] as? String {
        //   if screenToOpen == "checkInFlow" {
        //      // Access your router and navigate. This needs to be done carefully
        //      // as AppDelegate doesn't have direct access to SwiftUI environment objects.
        //      // You might use NotificationCenter to post an event that your UI observes.
        //      NotificationCenter.default.post(name: .navigateToMoodFlow, object: nil)
        //   }
        // }
        completionHandler()
    }
}
