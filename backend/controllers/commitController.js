const axios = require('axios');

class CommitController {
  async checkTodayCommit(req, res) {
    try {
      const { userId } = req.params;
      // TODO: Get user's GitHub token from Firebase
      const accessToken = 'user_token_from_firebase';

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const response = await axios.get(`https://api.github.com/user/events`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      const todayCommits = response.data.filter(event => {
        const eventDate = new Date(event.created_at);
        eventDate.setHours(0, 0, 0, 0);
        return event.type === 'PushEvent' && eventDate.getTime() === today.getTime();
      });

      const didCommit = todayCommits.length > 0;

      // TODO: Store commit status in Firebase
      
      res.json({
        userId,
        date: today.toISOString(),
        didCommit,
        commitCount: todayCommits.length
      });
    } catch (error) {
      console.error('Commit Check Error:', error);
      res.status(500).json({ error: 'Failed to check commits' });
    }
  }

  async scheduleNotification(req, res) {
    try {
      const { userId, reminderTime } = req.body;
      
      // TODO: Store reminder settings in Firebase
      // TODO: Schedule notification using node-cron

      res.json({
        message: 'Notification scheduled successfully',
        userId,
        reminderTime
      });
    } catch (error) {
      console.error('Notification Scheduling Error:', error);
      res.status(500).json({ error: 'Failed to schedule notification' });
    }
  }
}

module.exports = new CommitController(); 