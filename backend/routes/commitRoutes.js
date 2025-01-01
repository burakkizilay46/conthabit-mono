const express = require('express');
const router = express.Router();
const commitController = require('../controllers/commitController');
const authMiddleware = require('../middleware/auth');

// Get all commits
router.get('/commits', commitController.getCommits);

// Check if user has committed today
router.get('/commits/today', commitController.hasCommittedToday);

// Update user settings
router.post('/settings/reminder', commitController.updateReminderTime);
router.post('/settings/goal', commitController.updateCommitGoal);

module.exports = router; 