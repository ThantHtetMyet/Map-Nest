# Firebase Storage Setup Guide

## ✅ Yes, Firebase Storage has a FREE tier!

Firebase Storage (Blaze plan) includes a **generous free tier**:
- **5 GB storage** per month (free)
- **1 GB downloads** per day (free)
- **20,000 uploads** per day (free)

After the free tier, pricing is very affordable:
- Storage: $0.026 per GB/month
- Downloads: $0.12 per GB

## How to Enable Firebase Storage

### Step 1: Enable Storage in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **map-nest**
3. Click on **"Storage"** in the left menu
4. Click **"Get started"**
5. Choose **"Start in test mode"** (for development)
6. Select a location (preferably same as Firestore)
7. Click **"Done"**

### Step 2: Set Storage Security Rules

Go to **Storage → Rules** tab and use these rules for development:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /post_images/{allPaths=**} {
      // Allow read/write for all users (test mode)
      allow read, write: if true;
    }
  }
}
```

**⚠️ Important:** For production, you should add authentication and proper security rules.

### Step 3: Verify Storage is Working

After enabling Storage, the error should be resolved. The app will be able to:
- Upload images to Firebase Storage
- Get download URLs
- Store URLs in Firestore

## Troubleshooting

### Error: "object-not-found"
- **Solution:** Make sure Storage is enabled in Firebase Console
- Check that Storage rules allow read/write access
- Verify your Firebase project is on the Blaze plan (required for Storage, but still has free tier)

### Error: "permission-denied"
- **Solution:** Update Storage rules to allow access (use test mode rules above)

### Images not uploading
- Check internet connection
- Verify Storage bucket exists
- Check Firebase project configuration

## Free Tier Limits

The free tier is usually sufficient for:
- Small to medium apps
- Testing and development
- Apps with moderate image uploads

You'll only be charged if you exceed the free tier limits, and Firebase will notify you before charges apply.

