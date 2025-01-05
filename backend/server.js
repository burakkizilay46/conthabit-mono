const app = require('./app');
const notificationService = require('./services/notificationService');

const PORT = process.env.PORT || 3000;

app.listen(PORT, async () => {
  console.log(`Server is running on port ${PORT}`);
  
  // Initialize notifications for all users
  try {
    await notificationService.initializeAllReminders();
    console.log('Notification reminders initialized successfully');
  } catch (error) {
    console.error('Error initializing notification reminders:', error);
  }
}); 