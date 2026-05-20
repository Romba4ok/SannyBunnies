import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/teacher/profile_service_teacher.dart';
import 'package:sannybunnies/services/teacher/teacher_groups_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherGroupsPage extends StatefulWidget {
  const TeacherGroupsPage({Key? key}) : super(key: key);

  @override
  State<TeacherGroupsPage> createState() => _TeacherGroupsPageState();
}

class _TeacherGroupsPageState extends State<TeacherGroupsPage> {
  final Map<String, bool> _expandedGroups = {};
  final Map<String, String> _teacherNames = {};
  final Map<String, Map<String, dynamic>?> _parentCache = {};
  final Set<String> _teacherNamesLoading = {};
  final Set<String> _parentInfoLoading = {};

  
  late Stream<List<Map<String, dynamic>>> _groupsStream;

  @override
  void initState() {
    super.initState();
    
    _groupsStream = TeacherGroupsService.instance.groupsStream();
  }

  @override
  Widget build(BuildContext context) {
    final String currentTeacherUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentTeacherUid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF090707),
        body: Center(child: Text('Ошибка авторизации', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090707),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupsStream, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadPage();
          }

          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return const Center(child: Text('Группы не найдены', style: TextStyle(color: Colors.white70)));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Группы', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final groupData = groups[index];
                        final groupId = groupData['id']?.toString() ?? '';
                        final groupName = _normalizeString(groupData['name'], defaultValue: 'Группа без названия');
                        final teacherUids = _normalizeStringList(groupData['teacher_uids']);
                        final childrenIds = _normalizeStringList(groupData['children_uids']);
                        return _buildGroupCard(groupId, groupName, teacherUids, childrenIds);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(String groupId, String groupName, List<String> teacherUids, List<String> childrenIds) {
    _expandedGroups.putIfAbsent(groupId, () => false);
    final isExpanded = _expandedGroups[groupId] ?? false;
    final teacherText = _teacherNames[groupId] ?? 'Воспитатель: ${teacherUids.join(', ')}';

    if (teacherUids.isNotEmpty && !_teacherNames.containsKey(groupId)) {
      _ensureTeacherNamesLoaded(groupId, teacherUids);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expandedGroups[groupId] = !isExpanded),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3E1E58), Color(0xFF231228)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF6C3CA4), width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        teacherText,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Детей: ${childrenIds.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          _buildGroupContent(childrenIds),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGroupContent(List<String> childrenIds) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      
      
      stream: TeacherGroupsService.instance.childrenByIdsStream(childrenIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Color(0xFFA441DC)),
          ));
        }

        final children = snapshot.data ?? [];
        final sortedChildren = [...children];
        sortedChildren.sort((a, b) {
          final aStatus = _isInKindergarten(a['inKindergarten'] ?? a['attendanceStatus']);
          final bStatus = _isInKindergarten(b['inKindergarten'] ?? b['attendanceStatus']);
          return bStatus.toString().compareTo(aStatus.toString());
        });

        if (sortedChildren.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B151F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4B2F7F), width: 1),
            ),
            child: const Text('Нет детей в этой группе', style: TextStyle(color: Colors.white70)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedChildren.map((child) => _buildChildCard(child, context)).toList(),
        );
      },
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child, BuildContext context) {
    final String name = _normalizeString(child['name'], defaultValue: 'Имя');
    final String? photoUrl = child['photoUrl'] as String?;
    final String parentUid = _normalizeStringList(child['parent_uid']).firstWhere((uid) => uid.isNotEmpty, orElse: () => '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4B2F7F), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isInKindergarten(child['inKindergarten'] ?? child['attendanceStatus'])
                      ? const Color(0xFF25A278)
                      : const Color(0xFF6E6B7D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isInKindergarten(child['inKindergarten'] ?? child['attendanceStatus']) ? 'В садике' : 'Не в садике',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          if (parentUid.isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                if (!_parentCache.containsKey(parentUid)) {
                  _ensureParentInfoLoaded(parentUid);
                  
                  return const SizedBox(
                      height: 50,
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA441DC))))
                  );
                }

                final parentData = _parentCache[parentUid];
                if (parentData == null) {
                  return const SizedBox(height: 20, child: Text('Загрузка данных родителя...', style: TextStyle(color: Colors.white54, fontSize: 12)));
                }

                final String pName = _normalizeString(parentData['name'], defaultValue: 'Родитель');
                final String pPhone = _normalizeString(parentData['phone'], defaultValue: 'Нет телефона');
                final String? pPhotoUrl = parentData['photoUrl'] as String?;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B42DC), Color(0xFF4B2385)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        backgroundImage: pPhotoUrl != null && pPhotoUrl.isNotEmpty ? NetworkImage(pPhotoUrl) : null,
                        child: pPhotoUrl == null || pPhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 16) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(pPhone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showContactDialog(pPhone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Связаться',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _isInKindergarten(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'в садике' || normalized == 'true' || normalized == 'yes';
    }
    if (value is num) return value != 0;
    if (value is List) {
      return value.any((item) => _isInKindergarten(item));
    }
    return false;
  }

  String _normalizeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value.whereType<String>().join(', ');
    }
    return value.toString();
  }

  List<String> _normalizeStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) return value.whereType<String>().toList();
    return [value.toString()];
  }

  void _ensureTeacherNamesLoaded(String groupId, List<String> teacherUids) {
    if (groupId.isEmpty || teacherUids.isEmpty || _teacherNames.containsKey(groupId) || _teacherNamesLoading.contains(groupId)) {
      return;
    }
    _teacherNamesLoading.add(groupId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeacherNames(groupId, teacherUids);
    });
  }

  Future<void> _loadTeacherNames(String groupId, List<String> teacherUids) async {
    if (groupId.isEmpty || teacherUids.isEmpty) return;

    final names = <String>[];
    for (final uid in teacherUids) {
      final profile = await ProfileServiceTeacher.instance.fetchRemoteProfile(uid);
      if (profile != null && profile['name'] != null) {
        names.add(profile['name'].toString());
      } else {
        names.add(uid);
      }
    }

    if (!mounted) return; 
    setState(() {
      _teacherNames[groupId] = 'Воспитатель: ${names.join(', ')}';
    });
  }

  void _ensureParentInfoLoaded(String parentUid) {
    if (parentUid.isEmpty || _parentCache.containsKey(parentUid) || _parentInfoLoading.contains(parentUid)) {
      return;
    }
    _parentInfoLoading.add(parentUid);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParentInfo(parentUid);
    });
  }

  Future<void> _loadParentInfo(String parentUid) async {
    if (parentUid.isEmpty) return;

    final profile = await ProfileServiceTeacher.instance.getParentInfo(parentUid);
    if (!mounted) return; 

    setState(() {
      _parentCache[parentUid] = profile;
    });
  }

  String _normalizePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '';
    if (clean.length == 11 && clean.startsWith('8')) {
      return '7${clean.substring(1)}';
    }
    if (clean.length == 11 && clean.startsWith('7')) {
      return clean;
    }
    if (clean.length == 10) {
      return '7$clean';
    }
    return clean;
  }

  void _showContactDialog(String phone) {
    final normalized = _normalizePhone(phone);
    final displayPhone = normalized.isEmpty ? 'неизвестен' : '+$normalized';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          title: const Text('Связаться с родителем', style: TextStyle(color: Colors.white)),
          content: Text('Выберите способ связи с номером $displayPhone', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _callParent(phone);
              },
              child: const Text('Позвонить', style: TextStyle(color: Color(0xFFA441DC))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _launchWhatsApp(phone);
              },
              child: const Text('Написать', style: TextStyle(color: Color(0xFFA441DC))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callParent(String phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный номер телефона')));
      return;
    }

    final uri = Uri(scheme: 'tel', path: '+$normalized');
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось совершить звонок')));
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный номер телефона')));
      return;
    }

    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Не удалось запустить WhatsApp';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Установите WhatsApp или проверьте интернет')));
    }
  }
}