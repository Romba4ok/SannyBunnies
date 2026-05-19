import 'package:sannybunnies/services/user/groups_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class TeacherChildrenService {
  TeacherChildrenService._internal();
  static final TeacherChildrenService instance = TeacherChildrenService._internal();

  Stream<Map<String, dynamic>?> teacherGroupStream(String teacherUid) {
    return GroupsService.instance.teacherGroupStream(teacherUid);
  }

  Stream<List<Map<String, dynamic>>> childrenByIdsStream(List<String> ids) {
    return GroupsService.instance.childrenByIdsStream(ids);
  }

  Future<void> updateChildStatus(String childId, Map<String, dynamic> updates) async {
    if (childId.isEmpty || updates.isEmpty) return;
    await ProfileService.instance.updateChild(childId, updates);
  }

  Stream<Map<String, dynamic>?> childStream(String childId) {
    return ProfileService.instance.childStream(childId);
  }
}
