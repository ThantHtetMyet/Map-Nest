# Firebase Authentication Setup Guide

## Overview
This app uses Firebase Authentication for user sign-in and sign-up. When users create an account, they are automatically assigned the 'user' role which allows them to CRUD (Create, Read, Update, Delete) posts.

## Setup Steps

### Step 1: Enable Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **map-nest**
3. Click **"Authentication"** in the left menu
4. Click **"Get started"** (if not already enabled)
5. Click on the **"Sign-in method"** tab

### Step 2: Enable Email/Password Authentication

1. In the Sign-in method tab, click on **"Email/Password"**
2. Toggle **"Enable"** to ON
3. Click **"Save"**

### Step 3: Firestore Rules for Users Collection

Update your Firestore rules to allow users to read/write their own user document:

1. Go to **Firestore Database → Rules** tab
2. Update the rules to include:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Posts collection
    match /posts/{document=**} {
      // Allow authenticated users to read and write posts
      allow read, write: if request.auth != null;
    }
    
    // Users collection
    match /users/{userId} {
      // Allow users to read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      // Allow users to create their own document (during sign up)
      allow create: if request.auth != null && request.auth.uid == userId;
      // Allow users to update their own document
      allow update: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click **"Publish"**

## User Roles System

### Simple Role-Based Access Control
The app uses a **simple role system** where roles are stored directly in the user document:
- **`users` collection**: Each user has a `role` field ('user' or 'admin')
- **No separate roles table**: Roles are simple strings stored in user documents

### Default Roles

#### 1. User Role (Default)
- **Role**: `'user'` or `'USER'` (case-insensitive)
- **Permissions**:
  - ✅ Create posts
  - ✅ Read posts
  - ✅ Update posts
  - ✅ Delete posts
  - ❌ Manage users

#### 2. Admin Role
- **Role**: `'admin'` or `'ADMIN'` (case-insensitive)
- **Permissions**:
  - ✅ Create posts
  - ✅ Read posts
  - ✅ Update posts
  - ✅ Delete posts
  - ✅ Manage users

### Setting Up Roles

**No setup needed!** ✅

- When a user signs up, they automatically get `role: 'user'`
- Roles are stored directly in the user document
- To make a user admin, simply update their `role` field to `'admin'` in Firestore

**Automatic Role Initialization:**
- Roles are created with GUID document IDs
- Each role has a `name` field ('user', 'admin') for easy lookup
- The `roleId` in user documents references the GUID

**Manual Role Setup (if needed):**

If you need to manually create roles, you can use the Firestore console:

1. Go to **Firestore Database → Data** tab
2. Create a new collection called **`roles`**
3. Add documents with GUID IDs (use UUID generator) and the following structure:

**Example Role Document (GUID as Document ID):**
```javascript
// Document ID: "f9e8d7c6-b5a4-3210-9876-543210fedcba" (GUID)
{
  id: "f9e8d7c6-b5a4-3210-9876-543210fedcba", // Same as document ID
  name: "user", // For lookup
  displayName: "User",
  description: "Default user role with CRUD permissions for posts",
  permissions: {
    canCreatePost: true,
    canReadPost: true,
    canUpdatePost: true,
    canDeletePost: true,
    canManageUsers: false
  },
  createdAt: "2024-01-01T00:00:00Z"
}
```

### Changing User Role

To change a user's role:
1. Go to **Firestore Database → Data** tab
2. Find the user document in the `users` collection
3. Edit the `role` field
4. Change it from `"USER"` to `"ADMIN"` (or vice versa)
5. Save the document

That's it! The role is stored directly in the user document, so it's very simple to change.

## Data Structure

### User Document Structure

Each user document in Firestore has the following structure:

```javascript
{
  id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890", // GUID (Firebase Auth UID)
  email: "user@example.com",
  displayName: "Aye Moe Phyu", // Optional
  role: "USER", // Stored as uppercase: 'USER' or 'ADMIN'
  createdAt: "2025-01-30T12:00:00Z",
  lastLoginAt: "2025-01-30T12:00:00Z" // Updated on each sign in
}
```

**Note**: 
- `id` is a GUID (Firebase Auth UID from Firebase Authentication)
- `role` is stored as a string directly in the user document ('USER' or 'ADMIN')
- No separate roles table needed - simple and straightforward!

## Features

### Sign Up
- Users can create an account with email and password
- Display name is optional
- Password must be at least 6 characters
- User document is automatically created in Firestore with role 'user'

### Sign In
- Users can sign in with email and password
- Last login time is updated automatically
- User data is loaded from Firestore

### Sign Out
- Users can sign out from the map screen
- Sign out button is located at the top left (below theme toggle)

## Security Notes

1. **Authentication Required**: Users must be authenticated to access the app
2. **User Data Protection**: Users can only read/update their own user document
3. **Post Access**: All authenticated users can read and write posts
4. **Role-Based Access**: The role system is in place for future admin features

## Troubleshooting

### Error: "Email already in use"
- The email address is already registered
- Try signing in instead of signing up

### Error: "Weak password"
- Password must be at least 6 characters
- Use a stronger password

### Error: "User not found"
- The email is not registered
- Sign up first to create an account

### Error: "Wrong password"
- Check your password
- Use "Forgot password" if available (future feature)

## Next Steps

After setup:
1. ✅ Test sign up with a new account
2. ✅ Test sign in with the account
3. ✅ Verify user document is created in Firestore with role 'user'
4. ✅ Test creating a post (should work for authenticated users)
5. ✅ Test sign out functionality

## Free Tier

Firebase Authentication is **FREE** on the Spark plan with:
- Unlimited users
- Email/Password authentication
- No cost for authentication operations

Enjoy your authenticated app! 🎉

