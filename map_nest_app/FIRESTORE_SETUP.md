# Firestore Setup Guide (FREE)

## ✅ Firestore is FREE on Spark Plan!

You don't need to upgrade to Blaze plan for Firestore database. It's completely free!

## Setup Firestore

### Step 1: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **map-nest**
3. Click **"Firestore Database"** in the left menu
4. Click **"Create database"** (if not already created)
5. Choose **"Start in test mode"** (for development)
6. Select a **location** (choose closest to you)
7. Click **"Enable"**

### Step 2: Set Firestore Rules (Test Mode)

1. Go to **Firestore Database → Rules** tab
2. Replace the rules with:

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

3. Click **"Publish"**

### Step 3: Verify Setup

After enabling Firestore:
- ✅ Database is created
- ✅ Rules allow read/write
- ✅ Your app can now save posts

## Free Tier Limits

**Firestore FREE tier includes:**
- 1 GB storage
- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day

This is plenty for a small to medium app!

## Troubleshooting

### Error: "Permission denied"
- **Fix:** Check Firestore rules allow writes (use test mode rules above)

### Error: "Firestore is unavailable"
- **Fix:** Check internet connection
- Verify Firestore is enabled in Firebase Console

### Error: "Unauthenticated"
- **Fix:** Check Firebase configuration
- Verify `google-services.json` is in correct location

## Current Setup

✅ **Database:** Firestore (FREE - Spark plan)  
✅ **Images:** ImgBB (FREE)  
✅ **Total Cost:** $0.00

No payment method needed for Firestore!

