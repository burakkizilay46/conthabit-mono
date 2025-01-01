const admin = require('firebase-admin');

class FirebaseService {
  constructor() {
    let firebaseConfig;

    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      // Using JSON file
      firebaseConfig = {
        credential: admin.credential.applicationDefault()
      };
    } else {
      // Using environment variables
      firebaseConfig = {
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        })
      };
    }

    // Initialize Firebase Admin
    admin.initializeApp(firebaseConfig);
    this.db = admin.firestore();
  }

  async createUser(userData) {
    try {
      const userRef = this.db.collection('users').doc(userData.userId);
      await userRef.set(userData);
      return userData;
    } catch (error) {
      console.error('Firebase Create User Error:', error);
      throw error;
    }
  }

  async getUser(userId) {
    try {
      const userDoc = await this.db.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (error) {
      console.error('Firebase Get User Error:', error);
      throw error;
    }
  }

  async logCommit(commitData) {
    try {
      const commitRef = this.db.collection('commit_logs').doc();
      await commitRef.set({
        ...commitData,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      return commitData;
    } catch (error) {
      console.error('Firebase Log Commit Error:', error);
      throw error;
    }
  }

  async updateUserSettings(userId, settings) {
    try {
      const userRef = this.db.collection('users').doc(userId);
      await userRef.update(settings);
      return settings;
    } catch (error) {
      console.error('Firebase Update Settings Error:', error);
      throw error;
    }
  }
}

module.exports = new FirebaseService(); 