import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sannybunnies/pages/user/home/home.dart';
import 'package:sannybunnies/pages/user/interior/interior.dart';
import 'package:sannybunnies/pages/user/profile/profile.dart';
import 'package:sannybunnies/pages/user/schedule.dart';
import 'package:sannybunnies/pages/user/teachers.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';

class UserNavigationPage extends StatefulWidget {
  const UserNavigationPage({Key? key}) : super(key: key);

  @override
  State<UserNavigationPage> createState() => _UserNavigationPageState();
}

class _UserNavigationPageState extends State<UserNavigationPage> {
  int _currentIndex = 0;

  static final List<Widget> _pages = [
    const UserHomePage(),
    const UserSchedulePage(),
    const UserInteriorPage(),
    const UserTeachersPage(),
    const UserProfilePage(),
  ];

  final List<String> _labels = [
    'главная',
    'расписание',
    'интерьер',
    'воспитатели',
    'профиль',
  ];

  final List<String> _iconAssets = [
    'assets/images/dashboard_user/home.svg',
    'assets/images/dashboard_user/schedule.svg',
    'assets/images/dashboard_user/interior.svg',
    'assets/images/dashboard_user/teachers.svg',
    'assets/images/dashboard_user/profile.svg',
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _signOut() async {
    await LoginService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
      (route) => false,
    );
  }

  Widget _buildNavItem(int index) {
    final bool selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              SvgPicture.asset(
                _iconAssets[index],
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  selected ? const Color(0xFFA56EFF) : Colors.white70,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? const Color(0xFFA56EFF) : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: selected ? 35 : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFFAA56EFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      appBar: DashboardAppBarService.buildAppBar(
        context: context,
        onLogout: _signOut,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B191B),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: List.generate(_iconAssets.length, _buildNavItem),
            ),
          ),
        ),
      ),
    );
  }
}


