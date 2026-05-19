import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sannybunnies/services/database_service.dart';

class TeachersService {
  TeachersService._internal();
  static final TeachersService instance = TeachersService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadCachedTeachers() async {
    return await DatabaseService.instance.getCachedCollection('teachers');
  }

  Future<void> cacheTeachers(List<Map<String, dynamic>> teachers) async {
    await DatabaseService.instance.cacheCollection('teachers', teachers);
  }

  Stream<List<Map<String, dynamic>>> teachersStream() async* {
    final cached = await loadCachedTeachers();
    yield cached;

    yield* _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .asyncMap((snapshot) async {
      final teachers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      await cacheTeachers(teachers);
      return teachers;
    });
  }
}

