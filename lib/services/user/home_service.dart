import 'package:sannybunnies/services/user/news_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class HomeService {
  HomeService._internal();
  static final HomeService instance = HomeService._internal();

  Stream<Map<String, dynamic>?> firstNewsItemStream() {
    return NewsService.instance.newsStream().map((newsList) {
      if (newsList.isEmpty) return null;
      return newsList.first;
    });
  }

  Stream<Map<String, dynamic>?> kindergartenInfoStream() {
    return ProfileService.instance.kindergartenInfoStream();
  }

  Future<Map<String, dynamic>?> fetchKindergartenInfo() async {
    return await ProfileService.instance.getKindergartenInfo();
  }
}


