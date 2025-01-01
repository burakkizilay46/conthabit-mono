const axios = require('axios');

class AuthController {
  async githubAuth(req, res) {
    const clientId = process.env.GITHUB_CLIENT_ID;
    const redirectUri = process.env.GITHUB_REDIRECT_URI;
    
    const githubAuthUrl = `https://github.com/login/oauth/authorize?client_id=${clientId}&redirect_uri=${redirectUri}&scope=repo`;
    res.redirect(githubAuthUrl);
  }

  async githubCallback(req, res) {
    try {
      const { code } = req.query;
      const clientId = process.env.GITHUB_CLIENT_ID;
      const clientSecret = process.env.GITHUB_CLIENT_SECRET;

      // Exchange code for access token
      const tokenResponse = await axios.post('https://github.com/login/oauth/access_token', {
        client_id: clientId,
        client_secret: clientSecret,
        code,
      }, {
        headers: {
          Accept: 'application/json',
        },
      });

      const accessToken = tokenResponse.data.access_token;

      // Get user data from GitHub
      const userResponse = await axios.get('https://api.github.com/user', {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      // TODO: Store user data in Firebase
      // TODO: Generate JWT token for the user

      res.json({
        success: true,
        user: userResponse.data,
        token: accessToken,
      });
    } catch (error) {
      console.error('GitHub OAuth Error:', error);
      res.status(500).json({ error: 'Authentication failed' });
    }
  }
}

module.exports = new AuthController(); 