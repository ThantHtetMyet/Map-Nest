import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';

/// Firestore Service - Database is FREE on Spark plan
/// No payment method required for Firestore database
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test Firestore connection and read permissions
  Future<List<PostModel>> testReadPosts() async {
    try {
      debugPrint('🧪 Testing Firestore read...');
      final snapshot = await _firestore.collection('posts').get();
      debugPrint('🧪 Test read successful: ${snapshot.docs.length} documents found');
      
      final posts = <PostModel>[];
      for (var doc in snapshot.docs) {
        try {
          final post = PostModel.fromMap({
            'id': doc.id,
            ...doc.data(),
          });
          posts.add(post);
          debugPrint('🧪 Test: Loaded post ${post.id}');
        } catch (e) {
          debugPrint('🧪 Test: Error parsing ${doc.id}: $e');
        }
      }
      return posts;
    } on FirebaseException catch (e) {
      debugPrint('🧪 Test read failed: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Read permission denied. Check Firestore rules allow reads.');
      }
      rethrow;
    } catch (e) {
      debugPrint('🧪 Test read error: $e');
      rethrow;
    }
  }

  Stream<List<PostModel>> getPostsStream() {
    debugPrint('🔄 Setting up Firestore stream...');
    // Use simple query without orderBy to avoid index requirements
    // We'll sort manually in the app
    return _firestore
        .collection('posts')
        .snapshots()
        .map((snapshot) {
      debugPrint('📥 Firestore snapshot: ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No documents in snapshot - check Firestore rules allow reads');
      }
      
      final posts = <PostModel>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          debugPrint('📄 Processing doc ${doc.id}');
          debugPrint('   Data keys: ${data.keys.toList()}');
          
          final post = PostModel.fromMap({
            'id': doc.id,
            ...data,
          });
          
          posts.add(post);
          debugPrint('✅ Added post: ${post.id} at ${post.latitude}, ${post.longitude}');
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing doc ${doc.id}: $e');
          debugPrint('   Stack: $stackTrace');
          debugPrint('   Data: ${doc.data()}');
        }
      }
      
      // Sort by createdAt manually (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('📊 Total posts loaded: ${posts.length}');
      return posts;
    }).handleError((error, stackTrace) {
      debugPrint('❌ Error in getPostsStream: $error');
      debugPrint('   Stack: $stackTrace');
      // Return empty list on error instead of crashing
      return <PostModel>[];
    });
  }

  Future<void> createPost(PostModel post) async {
    try {
      debugPrint('📤 Creating post with ID: ${post.id}');
      debugPrint('📤 Post data: ${post.toMap()}');
      
      // Validate post data
      if (post.id.isEmpty) {
        throw Exception('Post ID cannot be empty');
      }
      if (post.imageUrls.isEmpty) {
        throw Exception('Post must have at least one image');
      }
      
      // Create the post in Firestore
      await _firestore.collection('posts').doc(post.id).set(post.toMap());
      
      debugPrint('✅ Post created successfully in Firestore: ${post.id}');
    } on FirebaseException catch (e) {
      String errorMsg = 'Firestore error';
      
      switch (e.code) {
        case 'permission-denied':
          errorMsg = 'Permission denied. Please check Firestore rules allow writes.';
          break;
        case 'unavailable':
          errorMsg = 'Firestore is unavailable. Check your internet connection.';
          break;
        case 'unauthenticated':
          errorMsg = 'Authentication required. Check Firebase configuration.';
          break;
        default:
          errorMsg = 'Firestore error: ${e.message} (Code: ${e.code})';
      }
      
      debugPrint('❌ Firestore error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ Error creating post: $e');
      rethrow;
    }
  }
}
