import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class MenuService {
  MenuService._internal();
  static final MenuService instance = MenuService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadCachedMenu() async {
    return await DatabaseService.instance.getCachedCollection('menu');
  }

  Future<void> cacheMenu(List<Map<String, dynamic>> menuItems) async {
    await DatabaseService.instance.cacheCollection('menu', menuItems);
  }

  Stream<List<Map<String, dynamic>>> menuStream() async* {
    final cachedMenu = await loadCachedMenu();
    if (cachedMenu.isNotEmpty) {
      yield cachedMenu;
    }

    yield* _firestore
        .collection('menu')
        .snapshots()
        .asyncMap((snapshot) async {
      final menuItems = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      await cacheMenu(menuItems);
      return menuItems;
    });
  }

  Stream<List<Map<String, dynamic>>> menuByGroupStream(String groupId) async* {
    final cachedMenu = await loadCachedMenu();
    final cachedGroupMenu = cachedMenu.where((item) => item['group_id'] == groupId).toList();
    if (cachedGroupMenu.isNotEmpty) {
      yield cachedGroupMenu;
    }

    yield* _firestore
        .collection('menu')
        .where('group_id', isEqualTo: groupId)
        .snapshots()
        .asyncMap((snapshot) async {
      final menuItems = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final currentCache = await loadCachedMenu();
      final updatedCache = currentCache.where((item) => item['group_id'] != groupId).toList();
      updatedCache.addAll(menuItems);
      await cacheMenu(updatedCache);

      return menuItems;
    });
  }
}
