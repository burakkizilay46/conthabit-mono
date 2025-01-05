const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/auth');

// All routes require authentication
router.use(authMiddleware);

// Update FCM token
router.post('/token', notificationController.updateFCMToken);

// Update notification settings
router.put('/settings', notificationController.updateNotificationSettings);

// Get notification settings
router.get('/settings', notificationController.getNotificationSettings);

module.exports = router; 