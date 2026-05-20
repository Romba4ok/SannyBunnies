import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class NewsService {
  NewsService._internal();
  static final NewsService instance = NewsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadCachedNews() async {
    return await DatabaseService.instance.getCachedCollection('news');
  }

  Future<void> cacheNews(List<Map<String, dynamic>> news) async {
    await DatabaseService.instance.cacheCollection('news', news);
  }

  Stream<List<Map<String, dynamic>>> newsStream() async* {
    final cachedNews = await loadCachedNews();
    if (cachedNews.isNotEmpty) {
      cachedNews.sort((a, b) {
        DateTime? toDateTime(dynamic value) {
          if (value == null) return null;
          if (value is DateTime) return value;
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          if (value is String) return DateTime.tryParse(value);
          if (value.runtimeType.toString().contains('Timestamp')) {
            try {
              return (value as dynamic).toDate() as DateTime;
            } catch (_) {
              return null;
            }
          }
          return null;
        }

        final createdA = toDateTime(a['createdAt']);
        final createdB = toDateTime(b['createdAt']);
        if (createdA != null && createdB != null) {
          return createdB.compareTo(createdA);
        }
        if (createdA != null) return -1;
        if (createdB != null) return 1;
        return (b['headline']?.toString() ?? '')
            .compareTo(a['headline']?.toString() ?? '');
      });
      yield cachedNews;
    }

    yield* _firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final news = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      news.sort((a, b) {
        DateTime? toDateTime(dynamic value) {
          if (value == null) return null;
          if (value is DateTime) return value;
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          if (value is String) return DateTime.tryParse(value);
          if (value.runtimeType.toString().contains('Timestamp')) {
            try {
              return (value as dynamic).toDate() as DateTime;
            } catch (_) {
              return null;
            }
          }
          return null;
        }

        final createdA = toDateTime(a['createdAt']);
        final createdB = toDateTime(b['createdAt']);
        if (createdA != null && createdB != null) {
          return createdB.compareTo(createdA);
        }
        if (createdA != null) return -1;
        if (createdB != null) return 1;
        return (b['headline']?.toString() ?? '')
            .compareTo(a['headline']?.toString() ?? '');
      });
      await cacheNews(news);
      return news;
    });
  }
}
