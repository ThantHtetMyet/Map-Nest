# Troubleshooting: "No Posts Found"

## Quick Checks

### 1. Check Firestore Read Rules

**Most Common Issue:** Firestore rules don't allow reads.

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select project: **map-nest**
3. Click **Firestore Database** → **Rules** tab
4. Make sure you have:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /posts/{document=**} {
      allow read, write: if true;
    }
  }
}
```

5. Click **"Publish"**

### 2. Verify Post Exists in Firestore

1. Go to Firebase Console → Firestore Database
2. Check if you see the **"posts"** collection
3. Check if your post document exists (ID: `1767033803362`)
4. Verify the data structure matches:
   - `contactName`
   - `contactNumber`
   - `imageUrls` (array)
   - `latitude`
   - `longitude`
   - `createdAt`

### 3. Check Debug Console

Look for these messages in your debug console:

✅ **Good signs:**
- `📥 Firestore snapshot: 1 documents`
- `✅ Added post: ...`
- `📊 Total posts loaded: 1`

❌ **Error signs:**
- `❌ Stream error: permission-denied`
- `🧪 Test read failed: ...`
- `⚠️ No documents in snapshot`

### 4. Try Manual Refresh

1. In the app, you should see a **"Refresh"** button
2. Tap it to manually reload posts
3. Check if posts appear

### 5. Check Internet Connection

- Make sure your device has internet
- Try on WiFi if mobile data isn't working
- Check if other Firebase features work

## Step-by-Step Fix

### Step 1: Verify Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /posts/{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Important:** Make sure `allow read` is there!

### Step 2: Restart the App

1. Close the app completely
2. Reopen it
3. Wait a few seconds for posts to load

### Step 3: Check Debug Output

In your IDE/console, look for:
- `🔄 Starting to load posts...`
- `🧪 Test read successful: X posts`
- `📬 Received X posts from stream`

### Step 4: Verify Data Format

In Firestore, your post should have:
- ✅ `imageUrls` (array) - NOT `imageUrl` (string)
- ✅ `createdAt` (string in ISO format)
- ✅ `latitude` and `longitude` (numbers)

## Common Issues

### Issue: "permission-denied"
**Fix:** Update Firestore rules to allow reads

### Issue: Stream not updating
**Fix:** 
1. Check internet connection
2. Restart the app
3. Use the Refresh button

### Issue: Posts exist but not showing
**Fix:**
1. Check if map is zoomed to wrong location
2. Use the "Show All Posts" button (map icon)
3. Check console for parsing errors

## Still Not Working?

1. **Check the debug console** - Look for error messages
2. **Verify Firestore rules** - Make sure reads are allowed
3. **Check post data format** - Make sure it matches PostModel
4. **Try creating a new post** - See if it appears
5. **Restart the app** - Sometimes streams need a restart

## Test Firestore Connection

The app now includes a test function that will:
- Try to read from Firestore
- Show specific error messages
- Help identify the exact problem

Check your debug console for messages starting with:
- 🧪 (test)
- 📥 (snapshot)
- ❌ (error)
- ✅ (success)

