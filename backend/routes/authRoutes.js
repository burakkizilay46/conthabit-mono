const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');

// GitHub OAuth routes
router.get('/github/init', authController.initiateOAuth);
router.post('/github/callback', authController.handleCallback);
router.get('/profile', authenticateToken, authController.getUserProfile);

// User management routes
router.post('/logout', authController.logout);
router.get('/user', authController.getCurrentUser);

module.exports = router; 