const axios = require('axios');
const { db } = require('../services/firebaseService');

const commitController = {
  getCommits: async (req, res) => {
    try {
      const userDoc = await db.collection('users').doc(req.user.userId.toString()).get();
      const userData = userDoc.data();

      const response = await axios.get('https://api.github.com/user/repos', {
        headers: { Authorization: `Bearer ${userData.accessToken}` }
      });

      const repos = response.data;
      const commits = [];

      // Get commits from each repository
      for (const repo of repos) {
        const commitResponse = await axios.get(
          `https://api.github.com/repos/${repo.full_name}/commits`,
          {
            headers: { Authorization: `Bearer ${userData.accessToken}` },
            params: { author: userData.username }
          }
        );

        commits.push(...commitResponse.data.map(commit => ({
          id: commit.sha,
          message: commit.commit.message,
          date: commit.commit.author.date,
          repository: repo.name,
          url: commit.html_url
        })));
      }

      res.json(commits);
    } catch (error) {
      console.error('Error fetching commits:', error);
      res.status(500).json({ error: 'Failed to fetch commits' });
    }
  },

  hasCommittedToday: async (req, res) => {
    try {
      const userDoc = await db.collection('users').doc(req.user.userId.toString()).get();
      const userData = userDoc.data();

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const response = await axios.get(
        `https://api.github.com/search/commits`,
        {
          headers: {
            Authorization: `Bearer ${userData.accessToken}`,
            Accept: 'application/vnd.github.cloak-preview'
          },
          params: {
            q: `author:${userData.username} committer-date:>${today.toISOString()}`
          }
        }
      );

      const hasCommitted = response.data.total_count > 0;
      res.json({ hasCommitted });
    } catch (error) {
      console.error('Error checking today\'s commits:', error);
      res.status(500).json({ error: 'Failed to check today\'s commits' });
    }
  },

  updateReminderTime: async (req, res) => {
    try {
      const { hour, minute } = req.body;
      
      await db.collection('users').doc(req.user.userId.toString()).update({
        reminderTime: { hour, minute }
      });

      res.json({ message: 'Reminder time updated successfully' });
    } catch (error) {
      console.error('Error updating reminder time:', error);
      res.status(500).json({ error: 'Failed to update reminder time' });
    }
  },

  updateCommitGoal: async (req, res) => {
    try {
      const { goal } = req.body;
      
      await db.collection('users').doc(req.user.userId.toString()).update({
        commitGoal: goal
      });

      res.json({ message: 'Commit goal updated successfully' });
    } catch (error) {
      console.error('Error updating commit goal:', error);
      res.status(500).json({ error: 'Failed to update commit goal' });
    }
  }
};

module.exports = commitController; 