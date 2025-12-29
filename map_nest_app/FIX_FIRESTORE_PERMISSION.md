# Fix Firestore Permission Denied Error

## The Problem
Error: "Permission denied. Please check Firestore rules allow writes."

This means your Firestore security rules are blocking write operations.

## Quick Fix (2 Minutes)

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
  }
}
```

### Step 4: Publish Rules
1. Click the **"Publish"** button
2. Wait for confirmation that rules are published

## That's It! ✅

After publishing the rules:
- Close the error dialog in your app
- Try creating a post again
- It should work now!

## What These Rules Do

- `allow read, write: if true;` - Allows anyone to read and write to the `posts` collection
- This is **test mode** - perfect for development
- For production, you should add authentication and proper security

## Verify It Worked

After updating rules, you should see:
- ✅ No more "Permission denied" errors
- ✅ Posts can be created successfully
- ✅ Posts appear on the map

## Production Rules (Later)

When you're ready for production, use rules like:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /posts/{document=**} {
      // Only allow authenticated users
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

But for now, the test mode rules above will work perfectly!

