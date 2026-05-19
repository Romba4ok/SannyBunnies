import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/pages/user/home/menu/detail_menu.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/user/groups_service.dart';
import 'package:sannybunnies/services/user/menu_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Константы для градиентов и цветов рамок, чтобы не выделять их при каждом билде
  static const List<List<Color>> _cardGradients = [
    [Color(0xFF00C566), Color(0xFF1A332C)],
    [Color(0xFFFF5B8D), Color(0xFF331A21)],
    [Color(0xFFFF8A48), Color(0xFF33231A)],
    [Color(0xFF8E8CFE), Color(0xFF1D1A33)],
  ];

  static const List<Color> _borderColors = [
    Color(0xFF4DFF9A),
    Color(0xFFFF94B4),
    Color(0xFFFFB38A),
    Color(0xFFC0BFFF),
  ];

  String? _selectedGroupId;
  bool _didSetInitialGroup = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await ProfileService.instance.loadCachedProfile(user.uid);
      if (mounted) setState(() => _userData = data);
      ProfileService.instance.profileStream(user.uid).listen((event) {
        if (mounted) setState(() => _userData = event);
      });
    }
  }

  Future<void> _signOut() async {
    await LoginService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _userData?['photoUrl'] as String?;
    final userName = _userData?['name'] as String? ?? '...';

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      appBar: DashboardAppBarService.buildAppBar(
        context: context,
        onLogout: _signOut,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Меню питания',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: GroupsService.instance.groupsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // 1. Получаем список и сортируем его (например, по имени или по какому-то полю)
                  final groups = snapshot.data!;
                  if (groups.isEmpty) return const SizedBox();

                  // Сортировка гарантирует, что первая группа всегда будет одной и той же
                  groups.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

                  // 2. Устанавливаем начальное значение только ЕСЛИ оно еще не выбрано
                  // ИЛИ если выбранный ID перестал существовать в списке
                  if (_selectedGroupId == null) {
                    final firstId = groups.first['id'];
                    _selectedGroupId = firstId;

                    // Используем отложенный вызов, чтобы не мешать отрисовке
                    Future.microtask(() {
                      if (mounted) setState(() {});
                    });
                  }

                  return Column(
                    children: [
                      _buildGroupTabs(groups),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFF562C70), // Темно-фиолетовый фон контента
                          child: _selectedGroupId == null
                              ? const SizedBox()
                              : _buildMenuGrid(_selectedGroupId!),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTabs(List<Map<String, dynamic>> groups) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFA442DC), // Светло-фиолетовый фон всей панели
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: groups.map((group) {
          final isSelected = _selectedGroupId == group['id'];

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedGroupId = group['id']),
              child: Container(
                // Внешний контейнер всегда прозрачный
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(5, 15, 5, 0), // Отступ сверху/снизу
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  // Регулируем ширину «ячейки» через отступы
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF562C70) : Colors.transparent,

                    // Если нужно закругление как на фото (только сверху и сильно),
                    // используйте:
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Text(
                    group['name'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuGrid(String groupId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: MenuService.instance.menuByGroupStream(groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
        final menuItems = snapshot.data!;
        if (menuItems.isEmpty) return const Center(child: Text('Меню пусто', style: TextStyle(color: Colors.white70)));

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 180),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 50,
            crossAxisSpacing: 20,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
              return RepaintBoundary(
                child: Transform.translate(
                  offset: Offset(0, index % 2 != 0 ? 70 : 0),
                  child: _buildMenuCard(menuItems[index], index),
                ),
              );
            },
        );
      },
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item, int index) {
    final gradient = _cardGradients[index % _cardGradients.length];
    final borderColor = _borderColors[index % _borderColors.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailMenuPage(menuItem: item))),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // ОСНОВНАЯ КАРТОЧКА
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 250),
            // Увеличили верхний отступ (100), чтобы текст не налезал на тарелку
            padding: const EdgeInsets.fromLTRB(12, 110, 12, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.9],
              ),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(
                color: borderColor.withAlpha((0.4 * 255).round()),
                width: 1.5,
              ),
            ),
            child: Column(
              // Убираем mainAxisAlignment.end, так как Spacer сам распределит место
              children: [
                Text(
                  item['meal'] ?? item['title'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2, // МАКСИМУМ 2 СТРОКИ
                  overflow: TextOverflow.ellipsis, // ТРИ ТОЧКИ В КОНЦЕ
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22, // Чуть уменьшил, чтобы 2 строки ложились лучше
                    height: 1.1,
                  ),
                ),
                const Spacer(), // ЗАПОЛНЯЕТ ВСЁ СВОБОДНОЕ МЕСТО, ПРИЖИМАЯ ККАЛ ВНИЗ
                Text(
                  '${item['kcal'] ?? '0'} ккал',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // ФОТО ТАРЕЛКИ
          Positioned(
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipOval(
                child: item['photo_url'] != null && (item['photo_url'] as String).isNotEmpty
                    ? DashboardAppBarService.buildCachedImage(
                        item['photo_url'] as String,
                        width: 120,
                        height: 120,
                        placeholder: Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.restaurant, color: Colors.white, size: 30),
                        ),
                        errorWidget: Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.restaurant, color: Colors.white, size: 30),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 30),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  }