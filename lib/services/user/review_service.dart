import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sannybunnies/services/database_service.dart';

class ReviewService {
  ReviewService._internal();
  static final ReviewService instance = ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> loadCachedReviews() async {
    return await DatabaseService.instance.getCachedCollection('reviews');
  }

  Future<void> cacheReviews(List<Map<String, dynamic>> items) async {
    await DatabaseService.instance.cacheCollection('reviews', items);
  }

  Stream<List<Map<String, dynamic>>> getReviewsStream() async* {
    final cachedReviews = await loadCachedReviews();
    if (cachedReviews.isNotEmpty) {
      yield cachedReviews;
    }

    yield* _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reviews = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          await cacheReviews(reviews);
          return reviews;
        });
  }

  Future<void> addReview({
    required String text,
    required double rating,
    required String userName,
    required String? userPhoto,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('reviews').add({
      'userId': user.uid,
      'userName': userName,
      'userPhoto': userPhoto,
      'text': text,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    
    
  }

  Future<void> updateReview(String reviewId, String text, double rating) async {
    await _firestore.collection('reviews').doc(reviewId).update({
      'text': text,
      'rating': rating,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
  }
}


