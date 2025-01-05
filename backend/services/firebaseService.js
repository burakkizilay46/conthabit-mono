const admin = require('firebase-admin');

// Debug environment variables
console.log('Firebase Config:', {
  projectId: process.env.FIREBASE_PROJECT_ID,
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  privateKeyLength: process.env.FIREBASE_PRIVATE_KEY?.length
});

// Initialize Firebase Admin with environment variables
const firebaseConfig = {
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
  })
};

// Initialize Firebase
admin.initializeApp(firebaseConfig);

// Get Firestore instance
const db = admin.firestore();

module.exports = { db, admin }; 