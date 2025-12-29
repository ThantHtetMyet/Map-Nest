import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class PostProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _lastError;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  PostProvider() {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔄 Starting to load posts...');
      
      // First, test if we can read from Firestore
      try {
        final testPosts = await _firestoreService.testReadPosts();
        debugPrint('🧪 Test read successful: ${testPosts.length} posts');
        if (testPosts.isNotEmpty) {
          _posts = testPosts;
          _isLoading = false;
          _lastError = null;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('🧪 Test read failed: $e');
        _lastError = e.toString();
      }
      
      // Then set up the stream for real-time updates
      _firestoreService.getPostsStream().listen(
        (posts) {
          debugPrint('📬 Received ${posts.length} posts from stream');
          _posts = posts;
          _isLoading = false;
          _lastError = null;
          notifyListeners();
          debugPrint('✅ Notified listeners with ${_posts.length} posts');
        },
        onError: (error, stackTrace) {
          debugPrint('❌ Stream error: $error');
          debugPrint('   Stack: $stackTrace');
          _isLoading = false;
          _lastError = error.toString();
          notifyListeners();
        },
        cancelOnError: false, // Keep listening even if there's an error
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error setting up stream: $e');
      debugPrint('   Stack: $stackTrace');
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createPost(PostModel post) async {
    try {
      _lastError = null;
      await _firestoreService.createPost(post);
      debugPrint('✅ Post created successfully: ${post.id}');
      // The stream will automatically update with the new post
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error creating post: $e');
      debugPrint('   Post data: ${post.toMap()}');
      return false;
    }
  }
  
  // Method to manually refresh posts
  Future<void> refreshPosts() async {
    debugPrint('🔄 Manually refreshing posts...');
    _isLoading = true;
    notifyListeners();
    
    try {
      // Test read first
      final testPosts = await _firestoreService.testReadPosts();
      debugPrint('🔄 Refresh: Loaded ${testPosts.length} posts');
      _posts = testPosts;
      _isLoading = false;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('🔄 Refresh failed: $e');
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }
}
