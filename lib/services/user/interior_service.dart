import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class InteriorService {
  InteriorService._internal();
  static final InteriorService instance = InteriorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadCachedInterior() async {
    return await DatabaseService.instance.getCachedCollection('interior');
  }

  Future<void> cacheInterior(List<Map<String, dynamic>> items) async {
    await DatabaseService.instance.cacheCollection('interior', items);
  }

  Stream<List<Map<String, dynamic>>> interiorStream() async* {
    final cached = await loadCachedInterior();
    yield cached;

    yield* _firestore.collection('interior').snapshots().asyncMap((snapshot) async {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      await cacheInterior(items);
      return items;
    });
  }
}


