const express = require('express');
const router = express.Router();
const commitController = require('../controllers/commitController');

// Commit check routes
router.get('/check-commit/:userId', commitController.checkTodayCommit);
router.post('/schedule-notification', commitController.scheduleNotification);

module.exports = router; 