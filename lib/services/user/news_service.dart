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
      yield cachedNews;
    }

    yield* _firestore
        .collection('news')
        .snapshots()
        .asyncMap((snapshot) async {
      final news = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      await cacheNews(news);
      return news;
    });
  }
}


