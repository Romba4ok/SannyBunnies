import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/groups_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';
import 'package:sannybunnies/services/user/schedule_service.dart';

class UserSchedulePage extends StatefulWidget {
  const UserSchedulePage({Key? key}) : super(key: key);

  @override
  State<UserSchedulePage> createState() => _UserSchedulePageState();
}

class _UserSchedulePageState extends State<UserSchedulePage> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingChildren = true;

  final List<String> _weekDaysEng = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    
    final cachedProfile = await ProfileService.instance.loadCachedProfile(
      currentUser.uid,
    );
    if (mounted) setState(() => _userData = cachedProfile);
    ProfileService.instance.profileStream(currentUser.uid).listen((data) {
      if (mounted) setState(() => _userData = data);
    });

    
    ProfileService.instance.childrenStream(currentUser.uid).listen((children) {
      if (mounted) {
        setState(() {
          _children = children;
          _isLoadingChildren = false;
          if (_selectedChild == null && _children.isNotEmpty) {
            _selectedChild = _children.first;
          } else if (_selectedChild != null) {
            try {
              _selectedChild = _children.firstWhere(
                (c) => c['id'] == _selectedChild!['id'],
              );
            } catch (_) {}
          }
        });
      }
    });
  }

  void _selectChild() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Выберите ребенка',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _children.map((child) {
                    final isSelected = _selectedChild?['id'] == child['id'];
                    final childPhotoUrl = child['photoUrl'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8E8CFE).withOpacity(0.1)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8E8CFE)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: childPhotoUrl != null && childPhotoUrl.isNotEmpty
                                ? _buildCachedImage(childPhotoUrl, width: 50, height: 50)
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.child_care, color: Colors.white54),
                                  ),
                          ),
                        ),
                        title: Text(
                          child['name'] ?? 'Без имени',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: StreamBuilder<Map<String, dynamic>?>(
                          stream: GroupsService.instance.groupStream(child['group_id'] ?? ''),
                          builder: (context, groupSnapshot) {
                            final groupData = groupSnapshot.data;
                            final groupName = groupData?['name']?.toString() ?? 'Группа не назначена';
                            return Text(
                              groupName,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF8E8CFE) : Colors.white54,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF8E8CFE))
                            : const Icon(Icons.circle_outlined, color: Colors.white24),
                        onTap: () {
                          setState(() => _selectedChild = child);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: _isLoadingChildren
          ? const LoadPage()
          : _children.isEmpty
              ? const Center(
                  child: Text(
                        'Сначала зарегистрируйте детей в садик',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedChild == null) return const LoadPage();

    final groupId = _selectedChild!['group_id'] as String? ?? '';
    final childName = _selectedChild!['name'] ?? 'Ребенок';
    final childPhotoUrl = _selectedChild!['photoUrl'] as String?;
    final inKindergarten = _selectedChild!['inKindergarten'] as bool? ?? false;
    final mood = _selectedChild!['mood'] as String? ?? 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: inKindergarten ? const Color(0xFF00C566) : const Color(0xFFA441DC),
                    width: 2,
                  ),
                  color: Colors.grey[800],
                ),
                child: ClipOval(
                  child: childPhotoUrl != null && childPhotoUrl.isNotEmpty
                      ? _buildCachedImage(childPhotoUrl, width: 60, height: 60)
                      : const Icon(Icons.child_care, color: Colors.white54, size: 32),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          childName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (mood != 'None') ...[
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: GroupsService.instance.groupStream(groupId),
                      builder: (context, groupSnapshot) {
                        final groupData = groupSnapshot.data;
                        final gName = groupData?['name'] ?? 'Без группы';
                        final ageInfo = (groupData?['age_from'] != null && groupData?['age_to'] != null)
                            ? ' (${groupData!['age_from']}-${groupData['age_to']} лет)'
                            : '';
                        return Text(
                          '$gName$ageInfo',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: _selectChild,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Выбрать ребенка', style: TextStyle(color: Colors.white, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.unfold_more, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFFA441DC), size: 24),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM d', 'ru_RU').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        _buildWeekCalendar(),

        
        Expanded(
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: ScheduleService.instance.groupScheduleStream(groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LoadPage();

              final scheduleDoc = snapshot.data;
              if (scheduleDoc == null) {
                return const Center(
                  child: Text('Расписание не найдено', style: TextStyle(color: Colors.white70)),
                );
              }

              final String dayKey = _weekDaysEng[_selectedDate.weekday - 1];
              
              List<dynamic> daySchedule = scheduleDoc[dayKey] is List 
                  ? scheduleDoc[dayKey] 
                  : (scheduleDoc['days']?[dayKey] ?? []);
              
              final String? globalTitle = scheduleDoc['title'] as String?;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  if (globalTitle != null && globalTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        globalTitle,
                        style: const TextStyle(color: Colors.white60, fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (daySchedule.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('На этот день событий нет', style: TextStyle(color: Colors.white70)),
                      ),
                    )
                  else
                    ...daySchedule.asMap().entries.map((entry) => _buildTimelineItem(entry.value, entry.key)).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF8E8CFE).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = firstDayOfWeek.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          final dayName = DateFormat('EE', 'ru_RU').format(date).toUpperCase();

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 45,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8E8CFE) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimelineItem(dynamic item, int index) {
    final colors = [
      const Color(0xFF00C566),
      const Color(0xFF8E8CFE),
      const Color(0xFFFFB94F),
      const Color(0xFFFF5B8D),
    ];
    final color = colors[index % colors.length];

    final String time = item['time'] ?? '';
    final String title = item['title'] ?? '';
    final String location = item['location'] ?? '';

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(child: Container(width: 2, color: Colors.white10)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedImage(String url, {double? width, double? height}) {
    return FutureBuilder<List<int>?>(
      future: ProfileService.instance.getCachedPhotoBytes(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        }
        return Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey,
            child: const Icon(Icons.person, color: Colors.white30),
          ),
        );
      },
    );
  }
}


