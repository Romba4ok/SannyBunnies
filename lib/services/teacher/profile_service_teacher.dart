import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class ProfileServiceTeacher {
  ProfileServiceTeacher._internal();
  static final ProfileServiceTeacher instance = ProfileServiceTeacher._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> loadCachedProfile(String uid) async {
    return await ProfileService.instance.loadCachedProfile(uid);
  }

  Future<void> cacheProfile(Map<String, dynamic> data, String uid) async {
    return await ProfileService.instance.cacheProfile(data, uid);
  }

  Future<Map<String, dynamic>?> fetchRemoteProfile(String uid) async {
    return await ProfileService.instance.fetchRemoteProfile(uid);
  }

  Stream<Map<String, dynamic>> teacherProfileStream([String? uid]) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return Stream.value({});
    }
    return ProfileService.instance.profileStream(userId);
  }

  Future<void> updateTeacherProfile(String uid, Map<String, dynamic> updates) async {
    return await ProfileService.instance.updateUserProfile(uid, updates);
  }

  Future<void> updateNotificationStatus(String uid, bool enabled) async {
    return await updateTeacherProfile(uid, {'notificationsEnabled': enabled});
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw 'Пользователь не найден';

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<String> uploadProfilePhoto(String uid, Uint8List bytes) async {
    return await ProfileService.instance.uploadProfilePhoto(uid, bytes);
  }

  Future<List<int>?> getCachedPhotoBytes(String photoUrl) async {
    return await ProfileService.instance.getCachedPhotoBytes(photoUrl);
  }

  Future<Map<String, dynamic>?> getKindergartenInfo() async {
    return await ProfileService.instance.getKindergartenInfo();
  }

  Future<void> updateChildStatus(String childId, Map<String, dynamic> updates) async {
    return await ProfileService.instance.updateChild(childId, updates);
  }

  Future<Map<String, dynamic>?> getParentInfo(String parentUid) async {
    return await ProfileService.instance.fetchRemoteProfile(parentUid);
  }
}
