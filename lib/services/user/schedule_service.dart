import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class ScheduleService {
  ScheduleService._internal();
  static final ScheduleService instance = ScheduleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Future<List<Map<String, dynamic>>> loadCachedSchedules() async {
    return await DatabaseService.instance.getCachedCollection('schedule');
  }

  Future<void> cacheSchedule(String docId, Map<String, dynamic> data) async {
    if (docId.isEmpty || data.isEmpty) return;
    final schedule = Map<String, dynamic>.from(data);
    schedule['id'] = docId;
    await DatabaseService.instance.cacheDocument('schedule', docId, schedule);
  }

  Stream<Map<String, dynamic>?> groupScheduleStream(String groupId) async* {
    if (groupId.isEmpty) {
      yield null;
      return;
    }

    final cachedSchedules = await loadCachedSchedules();
    final cached = cachedSchedules.firstWhere(
      (item) => item['group_id']?.toString() == groupId,
      orElse: () => {},
    );
    if (cached.isNotEmpty) {
      yield cached;
    }

    yield* _firestore
        .collection('schedule')
        .where('group_id', isEqualTo: groupId)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;

      
      for (final day in _days) {
        if (data[day] is List) {
          final List<dynamic> list = List.from(data[day]);
          list.sort((a, b) {
            final String timeA = a['time']?.toString() ?? '00:00';
            final String timeB = b['time']?.toString() ?? '00:00';
            return timeA.compareTo(timeB);
          });
          data[day] = list;
        }
      }

      
      if (data['days'] is Map<String, dynamic>) {
        final daysMap = Map<String, dynamic>.from(data['days']);
        for (final day in _days) {
          if (daysMap[day] is List) {
            final List<dynamic> list = List.from(daysMap[day]);
            list.sort((a, b) {
              final String timeA = a['time']?.toString() ?? '00:00';
              final String timeB = b['time']?.toString() ?? '00:00';
              return timeA.compareTo(timeB);
            });
            daysMap[day] = list;
          }
        }
        data['days'] = daysMap;
      }

      await cacheSchedule(doc.id, data);
      return data;
    });
  }
}


