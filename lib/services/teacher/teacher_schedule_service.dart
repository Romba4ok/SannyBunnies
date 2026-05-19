import 'package:sannybunnies/services/user/schedule_service.dart';

class TeacherScheduleService {
  TeacherScheduleService._internal();
  static final TeacherScheduleService instance = TeacherScheduleService._internal();

  Stream<Map<String, dynamic>?> groupScheduleStream(String groupId) {
    return ScheduleService.instance.groupScheduleStream(groupId);
  }
}
