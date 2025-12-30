# Firestore Rules for Users Collection

## Quick Fix for "Permission Denied" Error

The error `[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation` means your Firestore security rules are blocking writes to the `users` collection.

## Solution: Update Firestore Rules

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project: **map-nest**

### Step 2: Open Firestore Rules
1. Click **"Firestore Database"** in the left menu
2. Click the **"Rules"** tab at the top

### Step 3: Update Rules
Replace the existing rules with these (for test mode):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /posts/{document=**} {
      // Allow read and write for all users (test mode)
      allow read, write: if true;
    }
    match /users/{document=**} {
      // Allow read and write for all users (test mode)
      // Users can sign up and sign in without Firebase Auth
      allow read, write: if true;
    }
    match /reports/{document=**} {
      // Allow read and write for all users (test mode)
      allow read, write: if true;
    }
  }
}
```

### Step 4: Publish Rules
1. Click the **"Publish"** button
2. Wait for confirmation that rules are published

## That's It! ✅

After publishing the rules:
- Close the error dialog in your app
- Try signing up again
- It should work now!

## What These Rules Do

- `allow read, write: if true;` - Allows anyone to read and write to the collections
- This is **test mode** - perfect for development
- For production, you should add proper validation and security

## Important Notes

Since we're not using Firebase Authentication:
- Users are stored directly in Firestore `users` collection
- Passwords are hashed using SHA-256 before storing
- User sessions are managed using `shared_preferences`
- The `users` collection needs write access for sign-up to work

## Production Rules (Later)

When you're ready for production, you should add validation rules like:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow anyone to create a new user (sign up)
      allow create: if request.resource.data.keys().hasAll(['userId', 'password', 'displayName', 'mobileNumber', 'role', 'createdAt']);
      
      // Allow users to read their own data
      allow read: if true; // Or add userId validation
      
      // Allow users to update their own data (except password)
      allow update: if true; // Or add userId validation
    }
    match /posts/{document=**} {
      allow read: if true;
      allow write: if true; // Or add user validation
    }
  }
}
```

But for now, the test mode rules above will work perfectly for development!

