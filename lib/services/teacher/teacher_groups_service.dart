import 'package:sannybunnies/services/user/groups_service.dart';

class TeacherGroupsService {
  TeacherGroupsService._internal();
  static final TeacherGroupsService instance = TeacherGroupsService._internal();

  Stream<List<Map<String, dynamic>>> groupsStream() {
    return GroupsService.instance.groupsStream();
  }

  Stream<Map<String, dynamic>?> groupStream(String groupId) {
    return GroupsService.instance.groupStream(groupId);
  }

  Stream<Map<String, dynamic>?> teacherGroupStream(String teacherUid) {
    return GroupsService.instance.teacherGroupStream(teacherUid);
  }

  Stream<List<Map<String, dynamic>>> childrenByIdsStream(List<String> ids) {
    return GroupsService.instance.childrenByIdsStream(ids);
  }
}
