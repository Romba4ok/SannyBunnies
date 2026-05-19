import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sannybunnies/pages/teacher/home.dart';
import 'package:sannybunnies/pages/teacher/children.dart';
import 'package:sannybunnies/pages/teacher/schedule.dart';
import 'package:sannybunnies/pages/teacher/groups.dart';
import 'package:sannybunnies/pages/teacher/profile.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TeacherHomePage(),
    const TeacherChildrenPage(),
    const TeacherSchedulePage(),
    const TeacherGroupsPage(),
    const TeacherProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090707),
      body: Row(
        children: [
          // Side Navigation Bar
          Container(
            width: 85,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF3D1B5D), width: 1.5),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Bunny Logo
                Image.asset(
                  'assets/images/dashboard_teacher/sunny.png',
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 60),
                // Nav Items
                _buildNavItem(
                  0,
                  'assets/images/dashboard_teacher/home.svg',
                  'главная',
                ),
                _buildNavItem(
                  1,
                  'assets/images/dashboard_teacher/children.svg',
                  'Список детей',
                ),
                _buildNavItem(
                  2,
                  'assets/images/dashboard_user/schedule.svg',
                  'Расписание',
                ),
                _buildNavItem(
                  3,
                  'assets/images/dashboard_teacher/groups.svg',
                  'Группы',
                ),
                _buildNavItem(
                  4,
                  'assets/images/dashboard_teacher/profile.svg',
                  'Профиль',
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String assetPath, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFA441DC)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(color: Colors.white24, width: 0.5),
              ),
              child: SvgPicture.asset(
                assetPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : Colors.white60,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
