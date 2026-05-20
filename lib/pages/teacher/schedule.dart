import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/teacher/teacher_children_service.dart';
import 'package:sannybunnies/services/teacher/teacher_schedule_service.dart';

class TeacherSchedulePage extends StatefulWidget {
  const TeacherSchedulePage({super.key});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  final String _currentTeacherUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  DateTime _selectedDate = DateTime.now();

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
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTeacherUid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF131010),
        body: Center(
          child: Text(
            'Ошибка авторизации',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: TeacherChildrenService.instance.teacherGroupStream(_currentTeacherUid),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadPage();
        }

        final groupData = groupSnapshot.data;
        if (groupData == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF131010),
            body: Center(
              child: Text('Группа не найдена', style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        final String groupId = groupData['id']?.toString() ?? '';
        final String groupName = groupData['name']?.toString() ?? 'Группа';
        final String ageInfo = (groupData['age_from'] != null && groupData['age_to'] != null)
            ? ' (${groupData['age_from']}-${groupData['age_to']} лет)'
            : '';

        return Scaffold(
          backgroundColor: const Color(0xFF131010),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Расписание группы',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$groupName$ageInfo',
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFA441DC), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM d', 'ru_RU').format(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildWeekCalendar(),
              Expanded(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: TeacherScheduleService.instance.groupScheduleStream(groupId),
                  builder: (context, scheduleSnapshot) {
                    if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                      return const LoadPage();
                    }

                    final scheduleDoc = scheduleSnapshot.data;
                    if (scheduleDoc == null) {
                      return const Center(
                        child: Text('Расписание не найдено', style: TextStyle(color: Colors.white70)),
                      );
                    }

                    final String dayKey = _weekDaysEng[_selectedDate.weekday - 1];
                    final List<dynamic> daySchedule = scheduleDoc[dayKey] is List
                        ? scheduleDoc[dayKey]
                        : (scheduleDoc['days']?[dayKey] ?? []);
                    final String? globalTitle = scheduleDoc['title'] as String?;

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      children: [
                        if (globalTitle != null && globalTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              globalTitle,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
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
                          ...daySchedule
                              .asMap()
                              .entries
                              .map((entry) => _buildTimelineItem(entry.value, entry.key)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

    
    final ScrollController scrollController = ScrollController();

    return Container(
      height: 95,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8E8CFE).withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8E8CFE).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          
          GestureDetector(
            onTap: () {
              scrollController.animateTo(
                scrollController.offset - 100,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white60,
                size: 16,
              ),
            ),
          ),

          
          Expanded(
            child: ListView.builder(
              controller: scrollController, 
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = firstDayOfWeek.add(Duration(days: index));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildDayButton(date),
                );
              },
            ),
          ),

          
          GestureDetector(
            onTap: () {
              scrollController.animateTo(
                scrollController.offset + 100,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white60,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(DateTime date) {
    final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
    final dayName = DateFormat('EE', 'ru_RU').format(date).toUpperCase();

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        width: 55,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8E8CFE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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

    final time = item?['time']?.toString() ?? '—';
    final title = item?['title']?.toString() ?? 'Событие';
    final description = item?['description']?.toString() ?? '';

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
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
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
}
