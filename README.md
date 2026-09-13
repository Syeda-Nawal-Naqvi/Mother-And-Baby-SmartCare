# Mother & Baby SmartCare 🌸

A comprehensive Flutter health-tracking application designed to help mothers and families monitor maternal and infant health, manage medical records, shop for essentials, and stay connected with an admin-backed support system — all in one place.



## 📱 About the App

**Mother & Baby SmartCare** is a cross-platform mobile app (Android & iOS) built with **Flutter** and **Firebase**, designed to make pregnancy and early childhood health tracking simple, organized, and accessible. It supports multiple family roles (mother, father, caretaker) alongside a full **admin dashboard** for platform-wide management.



## ✨ Features

### 🔐 Authentication & Security
- Email/password and Google Sign-In
- Email verification flow
- Forgot password / reset via email
- Set password for Google-only accounts
- Login activity tracking across devices, with "new login detected" security alerts
- "Need Help" flow for users who are completely locked out (no account access required)

### 👩 Mother Health Tracker
- Mother profile with delivery history
- Weight tracking over time
- Blood pressure monitoring with clinical range categorization
- Glucose level logging
- Medical history (conditions, medicines, doctor notes)

### 👶 Baby Health Tracker
- Multiple baby profiles per account
- Weight tracking (kg/lb)
- Vaccination schedule & status
- Allergy records with reactions and advice
- Developmental milestone tracking
- Baby-specific medical history

### 📊 Records & Graphs
- Visual charts for both mother's and baby's tracked health data
- Per-baby record views for families with more than one child

### 📄 Share Health Records
- Auto-generated, professionally branded PDF health reports
- Share mother or baby records via email directly from the app
- Online-only gating so reports are always built from fresh data

### 🛍️ In-App Shop
- Browse maternal & baby care products by category
- Country-based product/category visibility
- Direct links to partner stores for checkout
- Admin-managed product catalog

### 🔔 Notifications
- In-app notification center (read/unread, retention policy)
- Local push notifications for feedback replies & admin broadcasts
- In-app notification sound with mute preference
- Admin can broadcast messages to all users

### 💬 Feedback & Support
- Users can submit feedback and view admin replies in-thread
- Admin feedback management dashboard
- "Need Help" requests routed to admins, replied to via email

### 🎨 Personalization
- Light and dark mode
- Multiple dark-mode color palettes to choose from

### 🛠️ Admin Panel
- Manage users, mothers, and baby profiles
- Manage shop categories & products
- Review and reply to feedback
- Handle "Need Help" requests
- Send broadcast notifications
- Admin-specific settings and profile



## 🧰 Tech Stack

| Category | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK ^3.0.0) |
| Backend | [Firebase](https://firebase.google.com) — Authentication, Cloud Firestore |
| State Management | Provider |
| UI | Google Fonts, Material 3, `flutter_screenutil`, Lottie animations |
| Charts | `fl_chart` |
| PDF Generation | `pdf` |
| Notifications | `flutter_local_notifications`, Firestore-backed in-app notifications |
| Sound | `audioplayers` |
| Location | `geolocator`, `geocoding` |
| Email | `flutter_email_sender`, `email_validator` |
| Local Storage | `shared_preferences` |
| Connectivity | `connectivity_plus` |
| Media | `image_picker` |
| App Icon | `flutter_launcher_icons` |



## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ≥ 3.0.0)
- A configured [Firebase](https://firebase.google.com/) project with **Authentication** (Email/Password + Google) and **Cloud Firestore** enabled
- Android Studio / Xcode for building on device or emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/<your-username>/Mother-And-Baby-SmartCare.git
cd Mother-And-Baby-SmartCare

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/)
2. Add your Android/iOS app to the project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) into their respective platform folders
4. Enable **Authentication** (Email/Password, Google Sign-In) and **Cloud Firestore**
5. Deploy the included `firestore.rules` to secure your database

### App Icon
The launcher icon is generated from `assets/icons/app_logo.png` via `flutter_launcher_icons`:
```bash
flutter pub run flutter_launcher_icons
```



## 📂 Project Structure

```
lib/
├── firebase_options.dart      # Firebase platform configuration
├── main.dart                  # App entry point & route definitions
├── models/                    # Data models (mother, baby, shop, notifications, etc.)
├── services/                  # Firebase, auth, sessions, notifications, PDF, shop
├── utils/                     # Contact links, countries list, lifecycle observer
├── widgets/                   # Shared reusable UI components
└── screens/
    ├── splash_screen.dart
    ├── onboarding/                 # First-run onboarding flow
    ├── auth/                       # Login, register, verify email, password recovery
    ├── userdashboard/              # Home, profile, settings, login activity
    ├── Motherhealthtracker/        # Mother health tracking screens
    ├── Babyhealthtracker/          # Baby health tracking screens
    ├── RecordsAndGraphs/           # Charts & historical record views
    ├── ShareRecords/               # PDF report generation & email sharing
    ├── Shop/                       # In-app shop
    ├── Notifications/              # Notification center
    ├── feedback/                   # User feedback screen
    └── admin/                      # Full admin dashboard & management screens
```



## 🔒 Firestore Data Model (high level)

- `users/{uid}` — root profile (role, blocked status, country, preferences)
  - `users/{uid}/mother_profile`, `mother_weight`, `blood_pressure`, `glucose`, `medical_history`
  - `users/{uid}/babies/{babyId}` and related `baby_weight`, `vaccinations`, `allergies`, `milestones`, `baby_medical_history`
  - `users/{uid}/sessions/{sessionId}` — device session tracking
- `feedback/{id}` — user feedback, visible to the submitter and admins
- `help_requests/{id}` — public-write collection for locked-out users
- `notifications/{id}` — top-level, recipient-scoped notification documents
- `shop_categories/{id}` and `shop_products/{id}` — admin-managed shop catalog

Security rules for all of the above are defined in `firestore.rules`.



## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues) if you'd like to contribute.



## 📧 Contact

For questions, feedback, or support, use the in-app **Contact Us** section, or open an issue on this repository.



## 📄 License

This project is currently unlicensed / private.
