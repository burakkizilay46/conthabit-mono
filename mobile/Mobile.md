# Mobile Documentation

## Project: GitHub Commit Reminder - Mobile

### Overview
The mobile app is the user-facing interface for the GitHub Commit Reminder project. It allows users to connect their GitHub accounts, view progress towards their commit goals, and configure reminders.

---

### **Requirements**
1. **Languages/Technologies:**
   - Flutter for cross-platform app development (Dart programming language).
   - Firebase for authentication and push notifications.
   - HTTP requests to interact with the Express.js backend.

2. **Third-party Packages:**
   - `http` for API calls.
   - `firebase_messaging` for notifications.
   - `flutter_secure_storage` for storing user tokens.
   - `flutter_screenutil` for responsive design.
   - `provider` or `flutter_bloc` for theme management.

---

### **Use Cases**
1. **Authentication:**
   - Users log in via GitHub OAuth to connect their accounts.

2. **Progress Tracking:**
   - Displays the user's progress towards their 1000-commit goal.

3. **Reminder Configuration:**
   - Users set or modify their daily reminder times.

4. **Theme Customization:**
   - Users can switch between light and dark themes.
   - Support for system theme detection.

---

### **App Screens**

1. **Login Screen:**
   - Button: "Connect with GitHub"
   - Action: Redirects to GitHub OAuth.

2. **Dashboard Screen:**
   - Displays:
     - Commit progress (percentage bar).
     - Daily status: "Committed Today?"

3. **Settings Screen:**
   - Options:
     - Set daily reminder time.
     - Adjust commit goal.
     - Theme selection (Light/Dark/System).

---

### **Responsive Design**

1. **Layout Principles:**
   - Fluid layouts using `LayoutBuilder` and `MediaQuery`.
   - Responsive typography with `TextScaler`.
   - Adaptive widgets based on screen size.
   - Support for both portrait and landscape orientations.

2. **Breakpoints:**
   - Small phones: < 360dp
   - Regular phones: 360dp - 600dp
   - Tablets: > 600dp
   - Foldables: Custom breakpoints for folded/unfolded states

3. **Responsive Patterns:**
   - Single column layout for phones.
   - Two-column layout for tablets.
   - Dynamic padding and margins based on screen size.
   - Flexible widgets that adapt to available space.

---

### **Theme System**

1. **Theme Modes:**
   - Light theme
   - Dark theme
   - System theme (follows device settings)

2. **Customizable Elements:**
   - Primary and accent colors
   - Text styles and typography
   - Component-specific themes
   - Custom color palettes

3. **Theme Implementation:**
   - Centralized theme data
   - Theme provider for state management
   - Persistent theme preferences
   - Smooth theme transitions

---

### **File Structure**
```
mobile/
├── lib/
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── notification_service.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   └── commit_model.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   └── helpers.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── theme_provider.dart
│   │   └── responsive_utils.dart
│   ├── main.dart
└── pubspec.yaml
```

---

### **PRD Summary**
1. **Features:**
   - GitHub OAuth login.
   - Progress tracking with visual indicators.
   - Reminder time configuration.
   - Responsive design across devices.
   - Theme customization options.

2. **Milestones:**
   - Week 1: Build login and dashboard screens.
   - Week 2: Implement API integration.
   - Week 3: Add Firebase notifications.
   - Week 4: Implement responsive design and theming.

3. **Success Metrics:**
   - Seamless login experience.
   - Accurate progress display and notifications.
   - Consistent UI across different screen sizes.
   - Smooth theme transitions.
