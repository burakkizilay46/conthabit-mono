const express = require('express');
const router = express.Router();
const milestoneController = require('../controllers/milestoneController');
const authMiddleware = require('../middleware/auth');

// Get user's milestones
router.get('/milestones', milestoneController.getMilestones);

module.exports = router; 