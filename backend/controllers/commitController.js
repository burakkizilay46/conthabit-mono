const axios = require('axios');
const { db } = require('../services/firebaseService');
const milestoneController = require('./milestoneController');

// Start date for commit counting (January 1st, 2025)
const COMMIT_COUNT_START_DATE = '2025-01-01T00:00:00Z';

const commitController = {
  getCommits: async (req, res) => {
    try {
      const userDoc = await db.collection('users').doc(req.user.userId.toString()).get();
      const userData = userDoc.data();

      // Use the search API to get all commits by the user
      const searchResponse = await axios.get(
        'https://api.github.com/search/commits',
        {
          headers: {
            Authorization: `Bearer ${userData.accessToken}`,
            Accept: 'application/vnd.github.cloak-preview'
          },
          params: {
            q: `author:${userData.username} committer-date:>${COMMIT_COUNT_START_DATE}`,
            per_page: 100,  // Increase results per page
            sort: 'committer-date',
            order: 'desc'
          }
        }
      );

      const commits = await Promise.all(
        searchResponse.data.items.map(async (item) => {
          // Get full commit details
          const commitResponse = await axios.get(item.url, {
            headers: { Authorization: `Bearer ${userData.accessToken}` }
          });
          const commit = commitResponse.data;
          
          return {
            id: commit.sha,
            message: commit.commit.message,
            date: commit.commit.author.date,
            repository: item.repository.name,
            url: commit.html_url
          };
        })
      );

      // Update user's total commits
      await db.collection('users').doc(req.user.userId.toString()).update({
        totalCommits: commits.length
      });

      // Check for new milestones
      const newMilestones = await milestoneController.checkAndUpdateMilestones(req.user.userId.toString());

      res.json({
        commits,
        newMilestones
      });
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

      // If committed today, update streak
      if (hasCommitted) {
        const lastCommitDate = userData.lastCommitDate ? new Date(userData.lastCommitDate) : null;
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        let currentStreak = userData.currentStreak || 0;
        
        if (lastCommitDate && lastCommitDate.toDateString() === yesterday.toDateString()) {
          // Continued streak
          currentStreak++;
        } else if (!lastCommitDate || lastCommitDate.toDateString() !== today.toDateString()) {
          // New streak
          currentStreak = 1;
        }

        await db.collection('users').doc(req.user.userId.toString()).update({
          lastCommitDate: today,
          currentStreak: currentStreak
        });

        // Check for new milestones
        const newMilestones = await milestoneController.checkAndUpdateMilestones(req.user.userId.toString());

        res.json({ 
          hasCommitted,
          currentStreak,
          newMilestones
        });
      } else {
        res.json({ 
          hasCommitted,
          currentStreak: userData.currentStreak || 0,
          newMilestones: []
        });
      }
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