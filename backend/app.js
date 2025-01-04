const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const rateLimiter = require('./middleware/rateLimiter');
const authMiddleware = require('./middleware/auth');
const { db } = require('./services/firebaseService');

// Import routes
const authRoutes = require('./routes/authRoutes');
const commitRoutes = require('./routes/commitRoutes');
const milestoneRoutes = require('./routes/milestoneRoutes');

// Load environment variables
dotenv.config();

// Initialize express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(rateLimiter);

// Public routes
app.use('/auth', authRoutes);

// Protected routes
app.use('/api', authMiddleware, commitRoutes);
app.use('/api', authMiddleware, milestoneRoutes);

// Basic health check route
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Firebase connection test
app.get('/test-firebase', async (req, res) => {
  try {
    // Try to access Firestore
    const testDoc = await db.collection('_test_').doc('connectivity').get();
    res.json({ status: 'Firebase connection successful' });
  } catch (error) {
    console.error('Firebase connection error:', error);
    res.status(500).json({ 
      status: 'Firebase connection failed', 
      error: error.message 
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

module.exports = app; 