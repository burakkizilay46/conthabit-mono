const { db } = require('../services/firebaseService');

const MILESTONE_DEFINITIONS = [
  {
    id: 'commit_25',
    title: '25 Commits',
    description: 'Complete 25 commits',
    iconCodePoint: 0xe838, // star icon
    category: 'commit',
    targetValue: 25
  },
  {
    id: 'commit_100',
    title: '100 Commits',
    description: 'Complete 100 commits',
    iconCodePoint: 0xe839, // star_border icon
    category: 'commit',
    targetValue: 100
  },
  {
    id: 'streak_7',
    title: '7-Day Streak',
    description: 'Maintain a 7-day commit streak',
    iconCodePoint: 0xe525, // local_fire_department icon
    category: 'streak',
    targetValue: 7
  },
  {
    id: 'streak_30',
    title: '30-Day Streak',
    description: 'Maintain a 30-day commit streak',
    iconCodePoint: 0xef6c, // whatshot icon
    category: 'streak',
    targetValue: 30
  },
  {
    id: 'goal_50',
    title: 'Halfway There',
    description: 'Reach 50% of your commit goal',
    iconCodePoint: 0xe153, // flag icon
    category: 'goal',
    targetValue: 50
  },
  {
    id: 'goal_100',
    title: 'Goal Achieved',
    description: 'Reach 100% of your commit goal',
    iconCodePoint: 0xe876, // done_all icon
    category: 'goal',
    targetValue: 100
  }
];

const milestoneController = {
  getMilestones: async (req, res) => {
    try {
      const userId = req.user.userId.toString();
      
      // Get user's milestones
      const milestonesSnapshot = await db.collection('milestones')
        .where('userId', '==', userId)
        .get();

      const userMilestones = new Map();
      milestonesSnapshot.forEach(doc => {
        userMilestones.set(doc.data().milestoneId, doc.data());
      });

      // Get user's commit data
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      const commitCount = userData.totalCommits || 0;
      const streakDays = userData.currentStreak || 0;
      const commitGoal = userData.commitGoal || 1000;
      const goalProgress = Math.round((commitCount / commitGoal) * 100);

      // Process all milestone definitions
      const milestones = MILESTONE_DEFINITIONS.map(definition => {
        const userMilestone = userMilestones.get(definition.id);
        let currentValue = 0;

        // Calculate current value based on category
        switch (definition.category) {
          case 'commit':
            currentValue = commitCount;
            break;
          case 'streak':
            currentValue = streakDays;
            break;
          case 'goal':
            currentValue = goalProgress;
            break;
        }

        return {
          ...definition,
          currentValue,
          unlockedAt: userMilestone?.unlockedAt || null
        };
      });

      res.json(milestones);
    } catch (error) {
      console.error('Error fetching milestones:', error);
      res.status(500).json({ error: 'Failed to fetch milestones' });
    }
  },

  checkAndUpdateMilestones: async (userId) => {
    try {
      // Get user's current data
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      const commitCount = userData.totalCommits || 0;
      const streakDays = userData.currentStreak || 0;
      const commitGoal = userData.commitGoal || 1000;
      const goalProgress = Math.round((commitCount / commitGoal) * 100);

      // Get user's existing milestones
      const milestonesSnapshot = await db.collection('milestones')
        .where('userId', '==', userId)
        .get();

      const existingMilestones = new Map();
      milestonesSnapshot.forEach(doc => {
        existingMilestones.set(doc.data().milestoneId, doc.data());
      });

      // Check each milestone definition
      const batch = db.batch();
      const newlyUnlockedMilestones = [];

      for (const definition of MILESTONE_DEFINITIONS) {
        let currentValue = 0;

        // Calculate current value based on category
        switch (definition.category) {
          case 'commit':
            currentValue = commitCount;
            break;
          case 'streak':
            currentValue = streakDays;
            break;
          case 'goal':
            currentValue = goalProgress;
            break;
        }

        // Check if milestone should be unlocked
        if (currentValue >= definition.targetValue && !existingMilestones.has(definition.id)) {
          const milestoneRef = db.collection('milestones').doc();
          batch.set(milestoneRef, {
            userId,
            milestoneId: definition.id,
            unlockedAt: new Date(),
            category: definition.category
          });
          newlyUnlockedMilestones.push(definition.id);
        }
      }

      await batch.commit();
      return newlyUnlockedMilestones;
    } catch (error) {
      console.error('Error checking and updating milestones:', error);
      return [];
    }
  }
};

module.exports = milestoneController; 