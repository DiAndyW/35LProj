// In your main server file or a dedicated scheduler file (e.g., scheduler.js)
import cron from 'node-cron';
import admin from 'firebase-admin'; // Assuming firebase-admin is initialized elsewhere
import UserModel from '../models/UserModel.js'; // Adjust path as needed
import moment from 'moment-timezone'; // For robust timezone handling


cron.schedule('* * * * *', async () => {
  const nowPST = moment().tz("America/Los_Angeles");
  const currentHourPST = nowPST.hour();
  const currentMinutePST = nowPST.minute();

  console.log(`[Cron Job] Running at: ${nowPST.format('YYYY-MM-DD HH:mm:ss')} PST. Checking for notifications for ${currentHourPST}:${currentMinutePST}.`);

  try {
    const usersToNotify = await UserModel.find({
      'preferences.pushNotificationsEnabled': true,
      'preferences.notificationHourPST': currentHourPST,
      'preferences.notificationMinutePST': currentMinutePST,
      fcmToken: { $exists: true, $ne: null, $ne: "" } 
    }).select('username fcmToken'); 

    if (usersToNotify.length > 0) {
      console.log(`[Cron Job] Found ${usersToNotify.length} users to notify.`);
    }

    for (const user of usersToNotify) {
      if (user.fcmToken) {
        const message = {
          notification: {
            title: ' Morii Time! ', 
            body: `Hey ${user.username}, it's time to capture your mood! What are you feeling right now? ✨`,
          },
          token: user.fcmToken,
          apns: { 
            payload: {
              aps: {
                sound: 'default', 
                badge: 1,         
              }
            }
          },
        };

        try {
          const response = await admin.messaging().send(message);
          console.log(`[Cron Job] Successfully sent message to ${user.username} (FCM ID: ${response})`);
        } catch (error) {
          console.error(`[Cron Job] Error sending message to ${user.username} (FCM Token: ${user.fcmToken}):`, error.message);
          // Handle specific FCM errors (e.g., token unregistration)
          if (error.code === 'messaging/registration-token-not-registered' || 
              error.code === 'messaging/invalid-registration-token') {
            console.log(`[Cron Job] FCM token for ${user.username} is invalid. Removing from DB.`);
            await UserModel.findByIdAndUpdate(user._id, { $set: { fcmToken: null } });
          }
        }
      }
    }
  } catch (dbError) {
    console.error('[Cron Job] Error querying users for notifications:', dbError);
  }
}, {
  scheduled: true,
  timezone: "America/Los_Angeles" 
});

console.log('[Scheduler] Notification scheduler started. Default notifications at 1 PM PST.');