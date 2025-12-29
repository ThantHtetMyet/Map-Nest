# Quick Fix: Firebase Storage Error

## The Error You're Seeing
"Firebase Storage error. Please ensure: 1. Storage is enabled in Firebase Console 2. Storage rules allow read/write access"

## Solution (5 Steps - Takes 2 minutes)

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/

### Step 2: Select Your Project
Click on your project: **map-nest**

### Step 3: Enable Storage
1. In the left menu, click **"Storage"**
2. Click the **"Get started"** button

### Step 4: Configure Storage
1. Choose **"Start in test mode"** (for development)
2. Select a **location** (same as Firestore if possible)
3. Click **"Done"**

### Step 5: Set Storage Rules
1. Go to **Storage → Rules** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /post_images/{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**

## That's It! ✅

After completing these steps:
- Close and reopen the app
- Try uploading images again
- The error should be gone!

## Why This Happens
Firebase Storage needs to be explicitly enabled. It's not automatically enabled when you create a Firebase project.

## Free Tier
Don't worry - Firebase Storage has a generous free tier:
- 5 GB storage/month (free)
- 1 GB downloads/day (free)
- 20,000 uploads/day (free)

