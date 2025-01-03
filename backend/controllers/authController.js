const axios = require('axios');
const jwt = require('jsonwebtoken');
const { db } = require('../services/firebaseService');

const authController = {
  initiateGitHubOAuth: async (req, res) => {
    try {
      const mobileRedirect = req.query.mobile_redirect;
      const redirectUri = 'https://conthabit-mono.onrender.com/auth/github/callback';
      
      // Store the mobile redirect URI in the session or temporary storage
      if (mobileRedirect) {
        // You might want to store this in a temporary storage or session
        global.mobileRedirectMap = global.mobileRedirectMap || new Map();
        const state = Math.random().toString(36).substring(7);
        global.mobileRedirectMap.set(state, mobileRedirect);
        
        const authUrl = `https://github.com/login/oauth/authorize?client_id=${process.env.GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=user,repo&state=${state}`;
        res.json({ authUrl });
      } else {
        const authUrl = `https://github.com/login/oauth/authorize?client_id=${process.env.GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=user,repo`;
        res.json({ authUrl });
      }
    } catch (error) {
      console.error('GitHub OAuth initiation error:', error);
      res.status(500).json({ error: 'Failed to initiate GitHub OAuth' });
    }
  },

  handleGitHubCallback: async (req, res) => {
    try {
      const { code, state } = req.query;
      if (!code) {
        return res.status(400).json({ error: 'No code provided' });
      }

      // Exchange code for access token
      const tokenResponse = await axios.post('https://github.com/login/oauth/access_token', {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
        redirect_uri: 'https://conthabit-mono.onrender.com/auth/github/callback'
      }, {
        headers: { Accept: 'application/json' }
      });

      const accessToken = tokenResponse.data.access_token;

      // Get user data from GitHub
      const userResponse = await axios.get('https://api.github.com/user', {
        headers: { Authorization: `Bearer ${accessToken}` }
      });

      const userData = userResponse.data;

      // Store user in Firebase
      await db.collection('users').doc(userData.id.toString()).set({
        githubId: userData.id,
        username: userData.login,
        email: userData.email,
        avatarUrl: userData.avatar_url,
        accessToken,
        createdAt: new Date()
      });

      // Generate JWT
      const token = jwt.sign(
        { userId: userData.id, username: userData.login },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      // Get the stored mobile redirect URI if it exists
      let redirectUrl;
      if (state && global.mobileRedirectMap) {
        const mobileRedirect = global.mobileRedirectMap.get(state);
        if (mobileRedirect) {
          redirectUrl = `${mobileRedirect}?token=${token}`;
          global.mobileRedirectMap.delete(state); // Clean up
        } else {
          redirectUrl = `conthabit://auth?token=${token}`;
        }
      } else {
        redirectUrl = `conthabit://auth?token=${token}`;
      }

      // Redirect back to the mobile app with the token
      res.redirect(redirectUrl);
    } catch (error) {
      console.error('GitHub OAuth callback error:', error);
      res.redirect('conthabit://auth?error=Failed to complete GitHub OAuth');
    }
  },

  logout: async (req, res) => {
    try {
      // Since we're using JWT, we just need to tell the client to remove the token
      res.json({ message: 'Logged out successfully' });
    } catch (error) {
      res.status(500).json({ error: 'Failed to logout' });
    }
  },

  getCurrentUser: async (req, res) => {
    try {
      const userDoc = await db.collection('users').doc(req.user.userId.toString()).get();
      if (!userDoc.exists) {
        return res.status(404).json({ error: 'User not found' });
      }
      const userData = userDoc.data();
      delete userData.accessToken; // Don't send sensitive data
      res.json(userData);
    } catch (error) {
      res.status(500).json({ error: 'Failed to get user data' });
    }
  }
};

module.exports = authController; 