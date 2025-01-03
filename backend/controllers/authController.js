const axios = require('axios');
const jwt = require('jsonwebtoken');
const { db } = require('../services/firebaseService');

const authController = {
  initiateGitHubOAuth: async (req, res) => {
    try {
      console.log('Received mobile_redirect:', req.query.mobile_redirect);
      console.log('Received backend_callback:', req.query.backend_callback);
      
      const mobileRedirect = req.query.mobile_redirect;
      const backendCallback = req.query.backend_callback || 'https://conthabit-mono.onrender.com/auth/github/callback';
      
      // Store the mobile redirect URI in the session or temporary storage
      if (mobileRedirect) {
        // You might want to store this in a temporary storage or session
        global.mobileRedirectMap = global.mobileRedirectMap || new Map();
        const state = Math.random().toString(36).substring(7);
        global.mobileRedirectMap.set(state, decodeURIComponent(mobileRedirect));
        console.log('Stored mobile redirect:', mobileRedirect, 'with state:', state);
        
        const authUrl = `https://github.com/login/oauth/authorize?client_id=${process.env.GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(backendCallback)}&scope=user,repo&state=${state}`;
        console.log('Generated auth URL:', authUrl);
        res.json({ authUrl });
      } else {
        const authUrl = `https://github.com/login/oauth/authorize?client_id=${process.env.GITHUB_CLIENT_ID}&redirect_uri=${encodeURIComponent(backendCallback)}&scope=user,repo`;
        res.json({ authUrl });
      }
    } catch (error) {
      console.error('GitHub OAuth initiation error:', error);
      res.status(500).json({ error: 'Failed to initiate GitHub OAuth' });
    }
  },

  handleGitHubCallback: async (req, res) => {
    try {
      console.log('Received callback with query params:', req.query);
      const { code, state } = req.query;
      
      if (!code) {
        return res.status(400).json({ error: 'No code provided' });
      }

      // Exchange code for access token
      const tokenResponse = await axios.post('https://github.com/login/oauth/access_token', {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      }, {
        headers: { Accept: 'application/json' }
      });

      const accessToken = tokenResponse.data.access_token;
      console.log('Received access token from GitHub');

      // Get user data from GitHub
      const userResponse = await axios.get('https://api.github.com/user', {
        headers: { Authorization: `Bearer ${accessToken}` }
      });

      const userData = userResponse.data;
      console.log('Received user data from GitHub for:', userData.login);

      // Store user in Firebase
      await db.collection('users').doc(userData.id.toString()).set({
        githubId: userData.id,
        username: userData.login,
        email: userData.email,
        avatarUrl: userData.avatar_url,
        accessToken,
        createdAt: new Date()
      });
      console.log('Stored user data in Firebase');

      // Generate JWT
      const token = jwt.sign(
        { userId: userData.id, username: userData.login },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      // Get the stored mobile redirect URI if it exists
      let redirectUrl;
      if (state && global.mobileRedirectMap) {
        const storedMobileRedirect = global.mobileRedirectMap.get(state);
        console.log('Retrieved stored mobile redirect:', storedMobileRedirect);
        if (storedMobileRedirect) {
          redirectUrl = `${storedMobileRedirect}?token=${token}`;
          global.mobileRedirectMap.delete(state); // Clean up
          console.log('Using stored mobile redirect URL:', redirectUrl);
        } else {
          redirectUrl = `conthabit://auth?token=${token}`;
          console.log('No stored mobile redirect found, using default:', redirectUrl);
        }
      } else {
        redirectUrl = `conthabit://auth?token=${token}`;
        console.log('No state or mobileRedirectMap, using default:', redirectUrl);
      }

      // Redirect back to the mobile app with the token
      console.log('Redirecting to:', redirectUrl);
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
  },

  getUserProfile: async (req, res) => {
    try {
      const userDoc = await db.collection('users').doc(req.user.userId.toString()).get();
      const userData = userDoc.data();

      const response = await axios.get('https://api.github.com/user', {
        headers: { 
          Authorization: `Bearer ${userData.accessToken}`,
          Accept: 'application/vnd.github.v3+json'
        }
      });

      res.json(response.data);
    } catch (error) {
      console.error('Error fetching user profile:', error);
      res.status(500).json({ error: 'Failed to fetch user profile' });
    }
  }
};

module.exports = authController; 
