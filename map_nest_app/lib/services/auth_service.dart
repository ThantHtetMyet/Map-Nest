import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _currentUserIdKey = 'current_user_id';

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).toStringAsFixed(0);
  }

  // Sign up with userId and password - store directly in Firestore
  Future<UserModel> signUp({
    required String userId,
    required String password,
    required String displayName,
    required String mobileNumber,
  }) async {
    try {
      // Check if userId already exists
      final existingUserQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        throw Exception('User ID already exists. Please choose a different User ID.');
      }

      // Generate unique document ID
      final String docId = _generateUserId();

      // Hash the password
      final String hashedPassword = _hashPassword(password);

      // Create user document in Firestore
      final userModel = UserModel(
        id: docId,
        userId: userId,
        displayName: displayName,
        mobileNumber: mobileNumber,
        role: 'user', // Default role is 'user'
        createdAt: DateTime.now(),
      );

      // Save user to Firestore with hashed password
      await _firestore.collection('users').doc(docId).set({
        ...userModel.toMap(),
        'password': hashedPassword, // Store hashed password separately
      });

      // Don't save session during sign-up - user needs to sign in
      // Session will be saved during sign-in

      return userModel;
    } catch (e) {
      if (e.toString().contains('already exists')) {
        rethrow;
      }
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with userId and password
  Future<UserModel> signIn({
    required String userId,
    required String password,
  }) async {
    try {
      // Hash the provided password
      final String hashedPassword = _hashPassword(password);

      // Find user by userId
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User ID not found. Please check your User ID and try again.');
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      // Verify password
      if (userData['password'] != hashedPassword) {
        throw Exception('Incorrect password. Please try again.');
      }

      // Update last login time
      await _firestore.collection('users').doc(userDoc.id).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      // Save current user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, userDoc.id);

      // Return user model (without password)
      return UserModel.fromMap({
        'id': userDoc.id,
        ...userData,
      });
    } catch (e) {
      if (e.toString().contains('not found') || e.toString().contains('Incorrect password')) {
        rethrow;
      }
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  // Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString(_currentUserIdKey);
      
      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // Remove password from user data before creating model
        userData.remove('password');
        return UserModel.fromMap({
          'id': userDoc.id,
          ...userData,
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUserModel();
    return user != null;
  }
}
