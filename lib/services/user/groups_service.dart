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

  Future<void> cacheGroup(String groupId, Map<String, dynamic> groupData) async {
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

    yield* _firestore
        .collection('groups')
        .snapshots()
        .asyncMap((snapshot) async {
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

    yield* _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .asyncMap((doc) async {
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

  Stream<List<Map<String, dynamic>>> childrenByIdsStream(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    // Firestore 'where in' limit is 10 (or 30 in some versions), 
    // but usually for a group it might be more. 
    // If > 10, we might need to chunk or just listen to all children and filter.
    // Given the small scale of a kindergarten group (usually < 30), we use chunking or stream all.
    // Let's use snapshots of the collection and filter by IDs for simplicity and reactivity.
    return _firestore.collection('children').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => ids.contains(doc.id))
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    });
  }
}
