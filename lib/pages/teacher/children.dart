import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/teacher/profile_service_teacher.dart';
import 'package:sannybunnies/services/teacher/teacher_children_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherChildrenPage extends StatefulWidget {
  const TeacherChildrenPage({Key? key}) : super(key: key);

  @override
  State<TeacherChildrenPage> createState() => _TeacherChildrenPageState();
}

class _TeacherChildrenPageState extends State<TeacherChildrenPage> {
  final String _currentTeacherUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  Map<String, dynamic>? _selectedChild;

  @override
  Widget build(BuildContext context) {
    if (_currentTeacherUid.isEmpty) {
      return const Center(child: Text('Ошибка авторизации', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: TeacherChildrenService.instance.teacherGroupStream(_currentTeacherUid),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadPage();
        }

        final groupData = groupSnapshot.data;
        if (groupData == null) {
          return const Center(child: Text('Группа не найдена', style: TextStyle(color: Colors.white70)));
        }

        final List<String> childrenIds = (groupData['children_uids'] as List<dynamic>? ?? [])
            .map((value) => value?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toList();
        final String groupName = groupData['name'] ?? 'Без названия';

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: TeacherChildrenService.instance.childrenByIdsStream(childrenIds),
          builder: (context, childrenSnapshot) {
            if (childrenSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadPage();
            }

            final children = childrenSnapshot.data ?? [];
            final totalChildren = children.length;
            final inKindergartenCount = children.where((c) => _isInKindergarten(c['inKindergarten'] ?? c['attendanceStatus'])).length;
            final absentCount = totalChildren - inKindergartenCount;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    _buildGroupHeader(groupName, totalChildren, inKindergartenCount, absentCount),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _selectedChild == null
                          ? _buildChildrenGrid(children)
                          : _buildChildDetail(_selectedChild!['id'], children),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupHeader(String groupName, int total, int present, int absent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 30, 15, 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF3E1E58), Color(0xFF231228)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF6C3CA4), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Группа: $groupName', style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildHeaderCard('Детей', '$present/$total')),
            const SizedBox(width: 12),
            Expanded(child: _buildHeaderCard('Отсутствуют', '$absent')),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B151F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4B2F7F), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChildrenGrid(List<Map<String, dynamic>> children) {
    if (children.isEmpty) {
      return const Center(child: Text('Дети не найдены', style: TextStyle(color: Colors.white70)));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        final String name = child['name'] ?? 'Имя';
        final String? photoUrl = child['photoUrl'];

        return GestureDetector(
          onTap: () => setState(() => _selectedChild = child),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFEC6F9C), Color(0xFFF295B6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white24,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildDetail(String childId, List<Map<String, dynamic>> allChildren) {
    final currentChild = allChildren.firstWhere(
      (c) => c['id']?.toString() == childId,
      orElse: () => <String, dynamic>{},
    );
    if (currentChild.isEmpty) return const SizedBox.shrink();

    final String name = _normalizeString(currentChild['name'], defaultValue: 'Без имени');
    final String? photoUrl = _normalizeNullableString(currentChild['photoUrl']);
    final bool isInKindergarten = _isInKindergarten(currentChild['inKindergarten'] ?? currentChild['attendanceStatus']);
    final String mood = _normalizeString(currentChild['mood'], defaultValue: 'Не известно');
    final List<String> parentUids = _normalizeStringList(currentChild['parent_uid']);
    final String parentUid = parentUids.isNotEmpty ? parentUids.first : '';
    final String features = _normalizeString(currentChild['features']);
    final String healthText = _normalizeString(currentChild['healthText']);

    return WillPopScope(
      onWillPop: () async {
        setState(() => _selectedChild = null);
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedChild = null),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF1B191B), Color(0xFF000000)]),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_left, color: Colors.white),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Статус посещения', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusButton('В садике', isInKindergarten, () => _updateChildStatus(childId, isInKindergarten: true)),
                const SizedBox(width: 12),
                _buildStatusButton('Не в садике', !isInKindergarten, () => _updateChildStatus(childId, isInKindergarten: false)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Настроение', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMoodButton('', Icons.help_outline, mood == '', () => _updateChildStatus(childId, mood: '')),
                _buildMoodButton('Отличное', Icons.sentiment_very_satisfied, mood == 'Отличное', () => _updateChildStatus(childId, mood: 'Отличное')),
                _buildMoodButton('Хорошее', Icons.sentiment_satisfied, mood == 'Хорошее', () => _updateChildStatus(childId, mood: 'Хорошее')),
                _buildMoodButton('Плохое', Icons.sentiment_dissatisfied, mood == 'Плохое', () => _updateChildStatus(childId, mood: 'Плохое')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Здоровье', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showEditHealthDialog(childId, healthText),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E2B3A), Color(0xFF13111A)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd.MM.yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      healthText.isEmpty ? 'Нажмите, чтобы добавить заметку о здоровье...' : healthText,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Особенности', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA441DC), Color(0xFF6B429C)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                features.isEmpty ? 'Особенности пока не заданы' : features,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Контакты родителя', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: ProfileServiceTeacher.instance.getParentInfo(parentUid),
              builder: (context, parentSnapshot) {
                if (parentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final parentData = parentSnapshot.data;
                if (parentData == null) {
                  return const Text('Информация о родителе не найдена', style: TextStyle(color: Colors.white38));
                }

                final String pName = parentData['name'] ?? 'Родитель';
                final String pPhone = parentData['phone'] ?? 'Нет телефона';

                final String? parentPhotoUrl = parentData['photoUrl'] as String?;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B42DC), Color(0xFF4B2385)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            backgroundImage: parentPhotoUrl != null && parentPhotoUrl.isNotEmpty ? NetworkImage(parentPhotoUrl) : null,
                            child: parentPhotoUrl == null || parentPhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(pPhone, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _showParentContactDialog(pPhone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Связаться', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: isActive ? Colors.white : Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isActive ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFA441DC) : const Color(0xFF1B191B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? Colors.transparent : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateChildStatus(
    String childId, {
    bool? isInKindergarten,
    String? mood,
    String? healthText,
  }) async {
    final Map<String, dynamic> updates = {};
    if (isInKindergarten != null) {
      updates['inKindergarten'] = isInKindergarten;
      updates['attendanceStatus'] = isInKindergarten ? 'В садике' : 'Забрали';
    }
    if (mood != null) updates['mood'] = mood;
    if (healthText != null) updates['healthText'] = healthText;

    try {
      await TeacherChildrenService.instance.updateChildStatus(childId, updates);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка обновления: $e')));
    }
  }

  void _showEditFeaturesDialog(String childId, String currentFeatures) {
    final controller = TextEditingController(text: currentFeatures);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B191B),
        title: const Text('Особенности (Заметки)', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите особенности...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA441DC))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA441DC), width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () async {
              await TeacherChildrenService.instance.updateChildStatus(childId, {'features': controller.text.trim()});
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Сохранить', style: TextStyle(color: Color(0xFFA441DC))),
          ),
        ],
      ),
    );
  }

  void _showEditHealthDialog(String childId, String currentHealth) {
    final controller = TextEditingController(text: currentHealth);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B191B),
        title: const Text('Здоровье', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите примечание о здоровье...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA441DC))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA441DC), width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              final datePrefix = DateFormat('dd.MM.yyyy').format(DateTime.now());
              final updatedText = text.isEmpty
                  ? ''
                  : (text.startsWith(datePrefix) ? text : '$datePrefix: $text');
              await _updateChildStatus(childId, healthText: updatedText);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Сохранить', style: TextStyle(color: Color(0xFFA441DC))),
          ),
        ],
      ),
    );
  }

  String _normalizeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      final stringItems = value.whereType<String>().toList();
      if (stringItems.isNotEmpty) return stringItems.join(', ');
      return value.map((item) => item.toString()).join(', ');
    }
    return value.toString();
  }

  String? _normalizeNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      final stringItems = value.whereType<String>().toList();
      if (stringItems.isNotEmpty) return stringItems.first;
      if (value.isNotEmpty) return value.first.toString();
      return null;
    }
    return value.toString();
  }

  List<String> _normalizeStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) return value.whereType<String>().toList();
    return [value.toString()];
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

  void _showParentContactDialog(String phone) {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Установите WhatsApp или проверьте интернет')));
    }
  }
}
