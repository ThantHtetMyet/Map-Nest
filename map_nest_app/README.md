# MapNest - Room Rent Posts App

A Flutter application that displays room rent posts on an interactive OpenStreetMap with real-time updates.

## Features

- 🗺️ Interactive map using OpenStreetMap
- 📍 Current location tracking with permission handling
- 📌 Display all room rent posts as markers on the map
- ➕ Create new posts with FAB (Floating Action Button)
- 📝 Post creation form with:
  - Contact Name (required)
  - Contact Number (required, with validation)
  - Image upload (camera or gallery, required)
  - Location selection (current location or map tap/long-press)
- 👆 Tap markers to view full post details
- 🔄 Real-time updates using Firebase Firestore

## Setup Instructions

### 1. Install Flutter Dependencies

```bash
cd map_nest_app
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android app to your Firebase project:
   - Package name: `com.example.map_nest_app`
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`
3. Enable Firestore Database in Firebase Console (test mode for development)
4. Enable Firebase Storage in Firebase Console (test mode for development)

### 3. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── post_model.dart      # Post data model
├── providers/
│   └── post_provider.dart   # State management for posts
├── screens/
│   ├── map_screen.dart      # Main map screen
│   ├── create_post_screen.dart  # Post creation form
│   └── post_detail_screen.dart   # Post details view
└── services/
    ├── firestore_service.dart    # Firebase Firestore operations
    └── location_service.dart     # Location services
```

## Important Notes

- Make sure to place `google-services.json` in `android/app/` folder
- Enable Firestore and Storage in Firebase Console
- Grant location and camera permissions when prompted
- The app uses Java 11 (compatible with most systems)

## License

This project is created for demonstration purposes.
