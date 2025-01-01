const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// GitHub OAuth routes
router.get('/github/init', authController.initiateGitHubOAuth);
router.post('/github/callback', authController.completeGitHubOAuth);

// User management routes
router.post('/logout', authController.logout);
router.get('/user', authController.getCurrentUser);

module.exports = router; 