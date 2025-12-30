import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  // Permission checks based on role (stored directly in user document)
  bool get canManagePosts => _user?.canManagePosts ?? false;
  bool get canCreatePost => canManagePosts; // Users and admins can create posts
  bool get canReadPost => canManagePosts; // Users and admins can read posts
  bool get canUpdatePost => canManagePosts; // Users and admins can update posts
  bool get canDeletePost => canManagePosts; // Users and admins can delete posts
  bool get canManageUsers => _user?.isAdmin ?? false; // Only admins can manage users
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    // Load user data on initialization
    initialize();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      _user = await _authService.getCurrentUserModel();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _user = null;
      notifyListeners();
    }
  }

  // Sign up
  Future<bool> signUp({
    required String userId,
    required String password,
    required String displayName,
    required String mobileNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        userId: userId,
        password: password,
        displayName: displayName,
        mobileNumber: mobileNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({
    required String userId,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(
        userId: userId,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize - check if user is already signed in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

