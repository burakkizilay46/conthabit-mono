const admin = require('firebase-admin');
const notificationService = require('../services/notificationService');

class NotificationController {
    async updateFCMToken(req, res) {
        try {
            const { userId } = req.user;
            const { fcmToken } = req.body;

            if (!userId) {
                console.error('User ID is missing in request');
                return res.status(401).json({ error: 'User ID not found' });
            }

            if (!fcmToken) {
                console.error('FCM token is missing in request');
                return res.status(400).json({ error: 'FCM token is required' });
            }

            console.log('Updating FCM token for user:', userId.toString());

            // Store the FCM token in Firestore
            const userDocRef = admin.firestore()
                .collection('users')
                .doc(userId.toString());

            await userDocRef.update({
                fcmToken,
                lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log('Successfully updated FCM token for user:', userId.toString());
            res.status(200).json({ message: 'FCM token updated successfully' });
        } catch (error) {
            console.error('Error updating FCM token:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    }

    async updateNotificationSettings(req, res) {
        try {
            const { userId } = req.user;
            const { enabled, reminderTime } = req.body;

            if (!userId) {
                console.error('User ID is missing in request');
                return res.status(401).json({ error: 'User ID not found' });
            }

            if (typeof enabled !== 'boolean' || !reminderTime) {
                console.error('Invalid settings:', { enabled, reminderTime });
                return res.status(400).json({ error: 'Invalid notification settings' });
            }

            console.log('Updating notification settings for user:', userId.toString(), { enabled, reminderTime });

            // Store notification settings in Firestore
            const userDocRef = admin.firestore()
                .collection('users')
                .doc(userId.toString());

            await userDocRef.update({
                notificationSettings: {
                    enabled,
                    reminderTime,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                }
            });

            // If notifications are enabled, schedule the reminder
            if (enabled) {
                const userDoc = await userDocRef.get();
                const fcmToken = userDoc.data()?.fcmToken;
                
                if (fcmToken) {
                    console.log('Scheduling reminder for user:', userId.toString());
                    await notificationService.scheduleReminder(userId.toString(), fcmToken, reminderTime);
                } else {
                    console.warn('No FCM token found for user:', userId.toString());
                }
            }

            console.log('Successfully updated notification settings for user:', userId.toString());
            res.status(200).json({ message: 'Notification settings updated successfully' });
        } catch (error) {
            console.error('Error updating notification settings:', error);
            res.status(500).json({ error: error.message || 'Internal server error' });
        }
    }

    async getNotificationSettings(req, res) {
        try {
            const { userId } = req.user;
            if (!userId) {
                return res.status(401).json({ error: 'User ID not found' });
            }

            const userDocRef = admin.firestore().collection('users').doc(userId.toString());
            const userDoc = await userDocRef.get();

            if (!userDoc.exists) {
                // Create default settings if user document doesn't exist
                const defaultSettings = {
                    enabled: true,
                    reminderTime: '20:00', // Default to 8 PM
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                };
                await userDocRef.set({
                    notificationSettings: defaultSettings,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
                return res.status(200).json(defaultSettings);
            }

            const settings = userDoc.data()?.notificationSettings || {
                enabled: true,
                reminderTime: '20:00', // Default to 8 PM
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            res.status(200).json(settings);
        } catch (error) {
            console.error('Error getting notification settings:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}

module.exports = new NotificationController(); 