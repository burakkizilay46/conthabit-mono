
# Backend Documentation

## Project: GitHub Commit Reminder - Backend

### Overview
The backend for the GitHub Commit Reminder project is responsible for handling user authentication via GitHub OAuth, fetching commit data, and managing notifications to ensure users meet their daily commit goals.

---

### **Requirements**
1. **Languages/Technologies:**
   - Node.js with Express.js framework.
   - Firebase Firestore for database storage.
   - GitHub OAuth for user authentication.

2. **Third-party Services/APIs:**
   - GitHub API for retrieving user activity.
   - Firebase Cloud Messaging for push notifications.
   - Node-cron for scheduling daily tasks.

---

### **Use Cases**
1. **User Authentication:**
   - Authenticate users using GitHub OAuth and store their access tokens securely.

2. **Daily Commit Check:**
   - Fetch the user's commit events from GitHub API to check if they committed today.

3. **Notification Trigger:**
   - Schedule a notification if the user has not committed by their set reminder time.

---

### **API Endpoints**
1. **Authentication**
   - `POST /auth/github`
     - Redirects users to GitHub for OAuth and retrieves their access tokens.
   - `GET /auth/callback`
     - Callback endpoint for GitHub OAuth.

2. **Commit Check**
   - `GET /check-commit/:userId`
     - Verifies if the user has made any commits today.
   - `POST /schedule-notification`
     - Schedules notifications for users who haven’t committed.

3. **User Management**
   - `POST /user`
     - Stores user information, including access token and reminder settings.

---

### **Database Schema**

#### **Users Collection**
```json
{
  "userId": "12345",
  "username": "john_doe",
  "access_token": "abcd1234",
  "daily_reminder_time": "18:00",
  "target_commits": 1000
}
```

#### **Commit Logs Collection**
```json
{
  "userId": "12345",
  "date": "2025-01-01",
  "did_commit": true
}
```

---

### **File Structure**
```
backend/
├── controllers/
│   ├── authController.js
│   ├── commitController.js
│   └── notificationController.js
├── routes/
│   ├── authRoutes.js
│   ├── commitRoutes.js
│   └── notificationRoutes.js
├── services/
│   ├── githubService.js
│   └── notificationService.js
├── models/
│   ├── userModel.js
│   └── commitModel.js
├── utils/
│   ├── cronScheduler.js
│   └── logger.js
├── app.js
└── server.js
```

---

### **PRD Summary**
1. **Features:**
   - Authenticate users via GitHub OAuth.
   - Check daily commit status.
   - Trigger notifications if no commit is made.

2. **Milestones:**
   - Week 1: OAuth implementation and Firestore setup.
   - Week 2: Commit checking and database integration.
   - Week 3: Notification system and testing.

3. **Success Metrics:**
   - Accurate daily commit checks for users.
   - Reliable notification delivery (95% uptime).

