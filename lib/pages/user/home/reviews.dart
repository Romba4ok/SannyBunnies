import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';
import 'package:sannybunnies/services/user/review_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({Key? key}) : super(key: key);

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ReviewService _reviewService = ReviewService.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    
    initializeDateFormatting('ru', null);
    _loadUserProfile();
  }

  Future<void> _signOut() async {
    await LoginService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
          (route) => false,
    );
  }

  Future<void> _loadUserProfile() async {
    if (_currentUserId != null) {
      final cachedProfile = await ProfileService.instance.loadCachedProfile(_currentUserId);
      if (mounted) {
        setState(() {
          _userProfile = cachedProfile;
        });
      }

      ProfileService.instance.profileStream(_currentUserId).listen((data) {
        if (mounted) {
          setState(() {
            _userProfile = data;
          });
        }
      });
    }
  }

  void _showReviewDialog({String? reviewId, String? initialText, double? initialRating}) {
    final TextEditingController textController = TextEditingController(text: initialText);
    double rating = initialRating ?? 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B191B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reviewId == null ? 'Оставить отзыв' : 'Редактировать отзыв',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1.0),
                  );
                }),
              ),
              TextField(
                controller: textController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ваш отзыв...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D1526),
                    side: const BorderSide(color: Colors.white24, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (textController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      if (reviewId == null) {
                        await _reviewService.addReview(
                          text: textController.text,
                          rating: rating,
                          userName: _userProfile?['name'] ?? 'Аноним',
                          userPhoto: _userProfile?['photoUrl'],
                        );
                      } else {
                        await _reviewService.updateReview(reviewId, textController.text, rating);
                      }
                      navigator.pop();
                    }
                  },
                  child: Text(reviewId == null ? 'Опубликовать' : 'Сохранить', style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _userProfile?['photoUrl'] as String?;
    final userName = _userProfile?['name'] as String? ?? 'Пользователь';

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      appBar: DashboardAppBarService.buildAppBar(
        context: context,
        onLogout: _signOut,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _reviewService.getReviewsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadPage();
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(child: Text('Пока нет отзывов', style: TextStyle(color: Colors.white54)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _ReviewCard(
                      review: review,
                      isMine: review['userId'] == _currentUserId,
                      onEdit: () => _showReviewDialog(
                        reviewId: review['id'],
                        initialText: review['text'],
                        initialRating: (review['rating'] as num).toDouble(),
                      ),
                      onDelete: () => _reviewService.deleteReview(review['id']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1526),
                  side: const BorderSide(color: Colors.white24, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _showReviewDialog(),
                child: const Text('Написать отзыв', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final createdAtValue = review['createdAt'];
    final DateTime? createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : createdAtValue is DateTime
            ? createdAtValue
            : createdAtValue is int
                ? DateTime.fromMillisecondsSinceEpoch(createdAtValue)
                : createdAtValue is String
                    ? DateTime.tryParse(createdAtValue)
                    : null;
    final String dateStr = createdAt != null ? DateFormat('d MMMM', 'ru').format(createdAt) : '';
    final double rating = (review['rating'] as num?)?.toDouble() ?? 5.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1526),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: FutureBuilder<List<int>?>(
                    future: review['userPhoto'] != null
                        ? ProfileService.instance.getCachedPhotoBytes(review['userPhoto'])
                        : Future.value(null),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.done && snap.data != null) {
                        return Image.memory(
                          Uint8List.fromList(snap.data!),
                          fit: BoxFit.cover,
                        );
                      }
                      if (review['userPhoto'] != null) {
                        return Image.network(
                          review['userPhoto'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white30),
                          ),
                        );
                      }
                      return Container(
                        color: Colors.grey,
                        child: const Icon(Icons.person, color: Colors.white30),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Аноним',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['text'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (isMine) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


