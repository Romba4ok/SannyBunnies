import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class FaqService {
  FaqService._internal();
  static final FaqService instance = FaqService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadCachedFaq() async {
    return await DatabaseService.instance.getCachedCollection('faq');
  }

  Future<void> cacheFaq(List<Map<String, dynamic>> items) async {
    await DatabaseService.instance.cacheCollection('faq', items);
  }

  Stream<List<Map<String, dynamic>>> faqStream() async* {
    final cachedFaq = await loadCachedFaq();
    if (cachedFaq.isNotEmpty) {
      yield cachedFaq;
    }

    yield* _firestore
        .collection('faq')
        .snapshots()
        .asyncMap((snapshot) async {
      final faqList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      await cacheFaq(faqList);
      return faqList;
    });
  }
}


