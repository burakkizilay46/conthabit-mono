const admin = require('firebase-admin');
const cron = require('node-cron');

class NotificationService {
    constructor() {
        this.messaging = admin.messaging();
        this.scheduledJobs = new Map();
        this.retryAttempts = new Map();
        this.maxRetries = 3;
    }

    async sendDailyReminder(userId, token, reminderTime, timezone) {
        try {
            const message = {
                notification: {
                    title: 'Daily Habit Reminder',
                    body: "Don't forget to check your habits for today!"
                },
                token: token,
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'daily_reminder',
                        priority: 'max',
                        defaultSound: true,
                        defaultVibrateTimings: true
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1
                        }
                    }
                },
                data: {
                    type: 'daily_reminder',
                    userId: userId,
                    scheduledTime: reminderTime,
                    timezone: timezone
                }
            };

            const response = await this.messaging.send(message);
            // Reset retry count on successful send
            this.retryAttempts.delete(userId);
            return response;
        } catch (error) {
            console.error('Error sending notification:', error);
            
            // Handle token expiration
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                await this.handleInvalidToken(userId);
                throw new Error('FCM token is invalid or not registered');
            }

            // Increment retry count and throw if exceeded
            const retryCount = (this.retryAttempts.get(userId) || 0) + 1;
            this.retryAttempts.set(userId, retryCount);

            if (retryCount > this.maxRetries) {
                this.retryAttempts.delete(userId);
                throw new Error(`Failed to send notification after ${this.maxRetries} attempts`);
            }

            throw error;
        }
    }

    async handleInvalidToken(userId) {
        try {
            // Remove invalid token from user document
            await admin.firestore()
                .collection('users')
                .doc(userId)
                .update({
                    fcmToken: admin.firestore.FieldValue.delete(),
                    notificationSettings: {
                        enabled: false,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    }
                });

            // Cancel any scheduled jobs
            this.cancelScheduledReminder(userId);
        } catch (error) {
            console.error(`Error handling invalid token for user ${userId}:`, error);
        }
    }

    async scheduleReminder(userId, token, reminderTime, timezone = 'UTC') {
        try {
            // Cancel existing job if any
            this.cancelScheduledReminder(userId);

            // Parse reminder time (format: "HH:mm")
            const [hours, minutes] = reminderTime.split(':').map(Number);
            
            // Create cron expression for daily reminder at specified time
            const cronExpression = `${minutes} ${hours} * * *`;

            // Validate cron expression
            if (!cron.validate(cronExpression)) {
                throw new Error('Invalid reminder time format');
            }

            // Schedule new job with error handling
            const job = cron.schedule(cronExpression, async () => {
                try {
                    // Verify user's current notification settings before sending
                    const userDoc = await admin.firestore()
                        .collection('users')
                        .doc(userId)
                        .get();

                    const settings = userDoc.data()?.notificationSettings;
                    const currentToken = userDoc.data()?.fcmToken;

                    if (settings?.enabled && settings?.reminderTime === reminderTime) {
                        // Use the most recent token
                        await this.sendDailyReminder(
                            userId,
                            currentToken || token,
                            reminderTime,
                            timezone
                        );
                    }
                } catch (error) {
                    console.error(`Error in scheduled reminder for user ${userId}:`, error);
                    
                    // If the error is not related to invalid token, retry after delay
                    if (!error.message.includes('FCM token is invalid')) {
                        setTimeout(() => {
                            this.scheduleReminder(userId, token, reminderTime, timezone)
                                .catch(console.error);
                        }, 5 * 60 * 1000); // Retry after 5 minutes
                    }
                }
            }, {
                timezone: timezone
            });

            // Store the job
            this.scheduledJobs.set(userId, job);

            console.log(`Reminder scheduled for user ${userId} at ${reminderTime} ${timezone}`);
            return true;
        } catch (error) {
            console.error('Error scheduling reminder:', error);
            throw error;
        }
    }

    cancelScheduledReminder(userId) {
        const existingJob = this.scheduledJobs.get(userId);
        if (existingJob) {
            existingJob.stop();
            this.scheduledJobs.delete(userId);
            console.log(`Cancelled scheduled reminder for user ${userId}`);
        }
    }

    // Initialize reminders for all users with enabled notifications
    async initializeAllReminders() {
        try {
            const usersSnapshot = await admin.firestore()
                .collection('users')
                .where('notificationSettings.enabled', '==', true)
                .get();

            for (const doc of usersSnapshot.docs) {
                const userId = doc.id;
                const userData = doc.data();
                const settings = userData.notificationSettings;
                const fcmToken = userData.fcmToken;

                if (settings?.reminderTime && fcmToken) {
                    await this.scheduleReminder(userId, fcmToken, settings.reminderTime);
                }
            }

            console.log(`Initialized reminders for ${usersSnapshot.size} users`);
        } catch (error) {
            console.error('Error initializing reminders:', error);
        }
    }
}

module.exports = new NotificationService(); 