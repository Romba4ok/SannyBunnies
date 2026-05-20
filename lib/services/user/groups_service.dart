import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class GroupsService {
  GroupsService._internal();
  static final GroupsService instance = GroupsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadCachedGroups() async {
    return await DatabaseService.instance.getCachedCollection('groups');
  }

  Future<Map<String, dynamic>?> loadCachedGroup(String groupId) async {
    if (groupId.isEmpty) return null;
    return await DatabaseService.instance.getCachedDocument('groups', groupId);
  }

  Future<void> cacheGroups(List<Map<String, dynamic>> groups) async {
    await DatabaseService.instance.cacheCollection('groups', groups);
  }

  Future<void> cacheGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    if (groupId.isEmpty || groupData.isEmpty) return;
    final item = Map<String, dynamic>.from(groupData);
    item['id'] = groupId;
    await DatabaseService.instance.cacheDocument('groups', groupId, item);
  }

  Stream<List<Map<String, dynamic>>> groupsStream() async* {
    final cachedGroups = await loadCachedGroups();
    if (cachedGroups.isNotEmpty) {
      yield cachedGroups;
    }

    yield* _firestore.collection('groups').snapshots().asyncMap((
      snapshot,
    ) async {
      final groups = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      groups.sort((a, b) {
        final ageA = int.tryParse(a['age_from']?.toString() ?? '0') ?? 0;
        final ageB = int.tryParse(b['age_from']?.toString() ?? '0') ?? 0;
        return ageA.compareTo(ageB);
      });

      await cacheGroups(groups);
      return groups;
    });
  }

  Stream<Map<String, dynamic>?> groupStream(String groupId) async* {
    if (groupId.isEmpty) {
      yield null;
      return;
    }

    final cachedGroup = await loadCachedGroup(groupId);
    if (cachedGroup != null) {
      yield cachedGroup;
    }

    yield* _firestore.collection('groups').doc(groupId).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      data['id'] = doc.id;
      await cacheGroup(doc.id, data);
      return data;
    });
  }

  Stream<Map<String, dynamic>?> teacherGroupStream(String teacherUid) {
    return _firestore
        .collection('groups')
        .where('teacher_uids', arrayContains: teacherUid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final data = snapshot.docs.first.data();
          data['id'] = snapshot.docs.first.id;
          return data;
        });
  }

  Future<List<String>> fetchTeacherGroupIds(String teacherUid) async {
    if (teacherUid.isEmpty) {
      print('[GroupsService] fetchTeacherGroupIds: teacherUid пуст');
      return [];
    }
    try {
      print('[GroupsService] Загружаю группы для учителя: $teacherUid');
      final snapshot = await _firestore
          .collection('groups')
          .where('teacher_uids', arrayContains: teacherUid)
          .get();

      final groupIds = snapshot.docs
          .map((doc) => doc.id)
          .where((id) => id.isNotEmpty)
          .toList();

      print(
        '[GroupsService] Найдено групп: ${groupIds.length}, IDs: $groupIds',
      );
      return groupIds;
    } catch (e) {
      print('[GroupsService] Ошибка fetchTeacherGroupIds: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> childrenByIdsStream(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    
    
    
    
    
    return _firestore.collection('children').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) => ids.contains(doc.id)).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
