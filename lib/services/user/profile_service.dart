import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sannybunnies/services/database_service.dart';

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>?> loadCachedProfile(String uid) async {
    if (uid.isEmpty) return null;
    final cachedUsers = await DatabaseService.instance.getCachedCollection(
      'users',
    );
    for (final item in cachedUsers) {
      if (item['id']?.toString() == uid) {
        return item;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> loadCachedChildren(String uid) async {
    if (uid.isEmpty) return [];
    return await DatabaseService.instance.getCachedCollection('children/$uid');
  }

  Future<void> cacheProfile(Map<String, dynamic> data, String uid) async {
    if (uid.isEmpty || data.isEmpty) return;
    final item = Map<String, dynamic>.from(data);
    item['id'] = uid;
    await DatabaseService.instance.cacheCollection('users', [item]);
  }

  Future<void> cacheChildren(
    String uid,
    List<Map<String, dynamic>> children,
  ) async {
    if (uid.isEmpty) return;
    final cached = children.where((item) => item.isNotEmpty).map((item) {
      final child = Map<String, dynamic>.from(item);
      if (child['id'] == null) {
        throw ArgumentError('Child item must contain id');
      }
      return child;
    }).toList();
    await DatabaseService.instance.cacheCollection('children/$uid', cached);
  }

  Future<List<Map<String, dynamic>>> fetchRemoteChildren(String uid) async {
    if (uid.isEmpty) return [];
    final snapshot = await _firestore
        .collection('children')
        .where('parent_uid', isEqualTo: uid)
        .get();

    final children = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    await cacheChildren(uid, children);
    return children;
  }

  Future<List<String>> getChildGroupIds(String uid) async {
    if (uid.isEmpty) {
      print('[ProfileService] getChildGroupIds: uid пуст');
      return [];
    }
    try {
      var children = await loadCachedChildren(uid);
      print(
        '[ProfileService] Загруженные кешированные дети: ${children.length}',
      );

      if (children.isEmpty) {
        print('[ProfileService] Дети не найдены в кеше, загружаю с сервера...');
        children = await fetchRemoteChildren(uid);
        print(
          '[ProfileService] Загруженные дети с сервера: ${children.length}',
        );
      }

      final groupIds = <String>{};
      for (final child in children) {
        final groupId = child['group_id'] as String?;
        if (groupId != null && groupId.isNotEmpty) {
          groupIds.add(groupId);
          print('[ProfileService] Добавлена groupId: $groupId');
        }
      }
      print('[ProfileService] Итоговые groupIds: $groupIds');
      return groupIds.toList();
    } catch (e) {
      print('[ProfileService] Ошибка getChildGroupIds: $e');
      return [];
    }
  }

  Future<List<int>?> getCachedPhotoBytes(String photoUrl) async {
    if (photoUrl.isEmpty) return null;
    return DatabaseService.instance.getCachedImage(photoUrl);
  }

  Future<void> cachePhotoUrl(String photoUrl) async {
    if (photoUrl.isEmpty) return;
    await DatabaseService.instance.cacheImage(photoUrl);
  }

  Future<Map<String, dynamic>?> fetchRemoteProfile(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    await cacheProfile(data, uid);
    return data;
  }

  Future<Map<String, dynamic>?> getCachedOrRemoteProfile(String uid) async {
    if (uid.isEmpty) return null;
    final cached = await loadCachedProfile(uid);
    if (cached != null) return cached;
    return await fetchRemoteProfile(uid);
  }

  Stream<Map<String, dynamic>> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().asyncMap((
      snapshot,
    ) async {
      final data = snapshot.data() ?? {};
      await cacheProfile(data, uid);
      return data;
    });
  }

  Stream<List<Map<String, dynamic>>> childrenStream(String uid) {
    return _firestore
        .collection('children')
        .where('parent_uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final children = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          
          children.sort((a, b) {
            DateTime? toDateTime(dynamic v) {
              if (v == null) return null;
              try {
                if (v is DateTime) return v;
                if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
                if (v is String) return DateTime.tryParse(v);
                
                if (v.runtimeType.toString().contains('Timestamp')) {
                  
                  try {
                    return (v as dynamic).toDate() as DateTime;
                  } catch (_) {
                    return null;
                  }
                }
              } catch (_) {}
              return null;
            }

            final ad = toDateTime(a['createdAt']);
            final bd = toDateTime(b['createdAt']);
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            return bd.compareTo(ad);
          });

          await cacheChildren(uid, children);
          return children;
        });
  }

  Stream<Map<String, dynamic>?> childStream(String childId) {
    if (childId.isEmpty) return Stream.value(null);
    return _firestore.collection('children').doc(childId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() ?? {};
      data['id'] = snapshot.id;
      return data;
    });
  }

  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    if (uid.isEmpty || updates.isEmpty) return;
    await _firestore.collection('users').doc(uid).update(updates);
  }

  Future<void> updateChild(String childId, Map<String, dynamic> updates) async {
    if (childId.isEmpty || updates.isEmpty) return;
    await _firestore.collection('children').doc(childId).update(updates);
  }

  Future<void> deleteChild(String uid, String childId) async {
    if (uid.isEmpty || childId.isEmpty) return;
    await _firestore.collection('children').doc(childId).delete();
  }

  String generateChildId(String uid) {
    final childrenCollection = _firestore.collection('children');
    return childrenCollection.doc().id;
  }

  Future<String> uploadChildPhoto(
    String uid,
    String childId,
    Uint8List bytes,
  ) async {
    if (uid.isEmpty || childId.isEmpty || bytes.isEmpty) {
      throw ArgumentError('Не указаны данные для загрузки фото ребёнка');
    }

    final storageRef = _storage
        .ref()
        .child('child_photos')
        .child(uid)
        .child('$childId.jpg');
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await storageRef.getDownloadURL();
  }

  Future<void> saveChild(
    String uid,
    String childId,
    Map<String, dynamic> childData, {
    Uint8List? photoBytes,
    bool isNew = false,
  }) async {
    if (uid.isEmpty || childId.isEmpty || childData.isEmpty) return;

    childData['parent_uid'] = uid;
    if (photoBytes != null) {
      childData['photoUrl'] = await uploadChildPhoto(uid, childId, photoBytes);
    }

    final childRef = _firestore.collection('children').doc(childId);
    if (isNew) {
      childData['createdAt'] = FieldValue.serverTimestamp();
      await childRef.set(childData);
    } else {
      await childRef.update(childData);
    }
  }

  Future<String> toggleChildRequestStatus(
    String uid,
    String childId,
    bool? currentRequestStatus,
  ) async {
    if (uid.isEmpty || childId.isEmpty) {
      return 'Ошибка: неверные параметры';
    }

    final bool? newRequestStatus;
    final String message;

    if (currentRequestStatus == true) {
      newRequestStatus = false;
      message = 'Ребенок отчислен';
    } else {
      newRequestStatus = currentRequestStatus == null ? false : null;
      message = newRequestStatus == null
          ? 'Заявка отправлена'
          : 'Заявка отменена';
    }

    final childRef = _firestore.collection('children').doc(childId);

    if (currentRequestStatus == true) {
      final childSnap = await childRef.get();
      final childData = childSnap.data() ?? {};
      final String? groupId = childData['group_id'] as String?;

      if (groupId != null && groupId.isNotEmpty) {
        try {
          await _firestore.collection('groups').doc(groupId).update({
            'children_uids': FieldValue.arrayRemove([childId]),
          });
        } catch (_) {}

        try {
          await childRef.update({
            'group_id': FieldValue.delete(),
            'group': FieldValue.delete(),
            'nanny': FieldValue.delete(),
          });
        } catch (_) {}
      }
    }

    await childRef.update({
      'requestStatus': newRequestStatus,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    return message;
  }

  Future<String> uploadProfilePhoto(String uid, Uint8List bytes) async {
    if (uid.isEmpty || bytes.isEmpty) {
      throw ArgumentError('Не указаны данные для загрузки фото');
    }

    final storageRef = _storage.ref().child('profile_photos').child('$uid.jpg');
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await storageRef.getDownloadURL();

    await _firestore.collection('users').doc(uid).set({
      'photoUrl': downloadUrl,
    }, SetOptions(merge: true));

    await cachePhotoUrl(downloadUrl);
    return downloadUrl;
  }

  Future<Map<String, dynamic>?> getKindergartenInfo() async {
    final cached = await loadCachedKindergartenInfo();
    if (cached != null) return cached;

    final doc = await _firestore.collection('kindergarten').doc('info').get();
    final data = doc.data();
    if (data != null) {
      await cacheKindergartenInfo(data);
    }
    return data;
  }

  Future<Map<String, dynamic>?> loadCachedKindergartenInfo() async {
    return await DatabaseService.instance.getCachedDocument(
      'kindergarten',
      'info',
    );
  }

  Future<void> cacheKindergartenInfo(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    await DatabaseService.instance.cacheDocument('kindergarten', 'info', data);
  }

  Future<Map<String, dynamic>?> fetchGroupById(String groupId) async {
    if (groupId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<String?> fetchUserNameById(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      return data == null ? null : (data['name'] as String?);
    } catch (e) {
      return null;
    }
  }

  Stream<Map<String, dynamic>?> kindergartenInfoStream() async* {
    final cached = await loadCachedKindergartenInfo();
    if (cached != null) {
      yield cached;
    }

    yield* _firestore
        .collection('kindergarten')
        .doc('info')
        .snapshots()
        .asyncMap((snapshot) async {
          final data = snapshot.data();
          if (data != null) {
            await cacheKindergartenInfo(data);
          }
          return data;
        });
  }
}
