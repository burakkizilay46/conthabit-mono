const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// GitHub OAuth routes
router.get('/github', authController.githubAuth);
router.get('/callback', authController.githubCallback);

module.exports = router; 