const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(path.join(__dirname, '../firebase-service-account.json')),
  projectId: process.env.FIREBASE_PROJECT_ID
});

// Get Firestore instance
const db = admin.firestore();

module.exports = { db, admin }; 