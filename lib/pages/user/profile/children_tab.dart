import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/user/profile/add_child.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class ChildrenTab extends StatefulWidget {
  final bool isChildrenLoading;
  final List<Map<String, dynamic>> children;

  const ChildrenTab({
    Key? key,
    required this.isChildrenLoading,
    required this.children,
  }) : super(key: key);

  @override
  State<ChildrenTab> createState() => _ChildrenTabState();
}

class _ChildrenTabState extends State<ChildrenTab> {
  final Set<String> _expandedChildIds = {};

  void _toggleChildExpanded(String childId) {
    setState(() {
      if (_expandedChildIds.contains(childId)) {
        _expandedChildIds.remove(childId);
      } else {
        _expandedChildIds.add(childId);
      }
    });
  }

  Future<void> _navigateToAddChildPage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddChildPage(parentUid: currentUser.uid),
      ),
    );

    if (added == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ребёнок успешно добавлен')));
    }
  }

  Future<void> _editChild(Map<String, dynamic> child) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddChildPage(
          parentUid: currentUser.uid,
          initialData: child,
        ),
      ),
    );

    if (updated == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные ребенка обновлены')),
      );
    }
  }

  Future<void> _deleteChild(String childId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B191B),
        title: const Text('Удалить ребенка?'),
        content: const Text(
          'Вы действительно хотите удалить данные этого ребенка?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(0xFFFF5A5F)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProfileService.instance.deleteChild(currentUser.uid, childId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ребенок удален')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isChildrenLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFA441DC)),
        ),
      );
    }

    if (widget.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Пока у вас нет зарегистрированных детей',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildAddChildButton(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int index = 0; index < widget.children.length; index++) ...[
            _buildChildHeader(index),
            if (_expandedChildIds.contains(
              widget.children[index]['id'] as String? ?? '$index',
            )) ...[
              const SizedBox(height: 12),
              _buildExpandedChildCard(widget.children[index]),
            ],
            const SizedBox(height: 20),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: _buildAddChildButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildChildHeader(int index) {
    final child = widget.children[index];
    final childId = child['id'] as String? ?? '$index';
    final isExpanded = _expandedChildIds.contains(childId);
    final name = child['name'] as String? ?? 'Ребёнок';

    return Column(
      children: [
        GestureDetector(
          onTap: () => _toggleChildExpanded(childId),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Icon(
                  !isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        !isExpanded
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  color: Color(0xFFA441DC),
                  thickness: 1.0,
                  height: 1,
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildExpandedChildCard(Map<String, dynamic> child) {
    final photoUrl = child['photoUrl'] as String?;
    final birthDate = child['birthDate'] as String? ?? 'Не указано';
    final nanny = child['nanny'] as String? ?? 'Не назначен';
    final group = child['group'] as String? ?? 'Не назначена';

    final bool? requestStatus = child['requestStatus'] as bool?;
    final String status = requestStatus == true
        ? 'Зачислен(а)'
        : requestStatus == null
            ? 'На рассмотрении'
            : 'Не зачислен(а)';

    final features = List<String>.from(
      child['features'] as List<dynamic>? ?? [],
    ).where((f) => f.trim().isNotEmpty).toList();

    final healthText = child['healthText'] as String? ??
        'Информация о здоровье появится после зачисления и обследования.';

    final isInKindergarten = child['inKindergarten'] as bool? ?? false;
    final mood = child['mood'] as String? ?? 'Нет данных';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131010),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFA441DC).withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA441DC).withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: const Color(0xFFA441DC).withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA441DC), Color(0xFF6B1DAE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? FutureBuilder<List<int>?>(
                            future: ProfileService.instance.getCachedPhotoBytes(photoUrl),
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.done && snap.data != null) {
                                return Image.memory(
                                  Uint8List.fromList(snap.data!),
                                  fit: BoxFit.cover,
                                );
                              }
                              if (snap.connectionState == ConnectionState.waiting) {
                                return Container(
                                  color: Colors.black.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Color(0xFFA441DC)),
                                  ),
                                );
                              }
                              return Image.network(photoUrl, fit: BoxFit.cover);
                            },
                          )
                        : Container(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Основные данные',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.info_outline, color: Colors.white, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Дата рождения', birthDate),
                _buildDivider(),
                _buildInfoRow('Воспитатель', nanny),
                _buildDivider(),
                _buildInfoRow('Группа', group),
                _buildDivider(),
                _buildInfoRow('Статус', status),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Особенности',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (int index = 0; index < 3; index++) ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            index < features.length ? features[index] : '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                          ),
                        ),
                      ),
                      if (index < 2) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusBox(
                'Статус',
                isInKindergarten ? 'В садике' : 'Не в садике',
                isInKindergarten ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              _buildStatusBox(
                'Настроение',
                mood,
                mood.toLowerCase() == 'отличное'
                    ? Colors.green
                    : mood.toLowerCase() == 'хорошее'
                        ? Colors.yellow
                        : mood.toLowerCase() == 'плохое'
                            ? Colors.red
                            : Colors.grey,
                isMood: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF420D0E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            color: Colors.white,
                            size: 23,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ЗДОРОВЬЕ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 18,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 23,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        healthText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.4,
                        ),
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton('Редактировать', () => _editChild(child)),
              const SizedBox(width: 12),
              _buildActionButton(
                'Удалить',
                () => _deleteChild(child['id'] as String? ?? ''),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(color: Colors.white.withOpacity(0.3), height: 8);

  Widget _buildStatusBox(
    String title,
    String value,
    Color dotColor, {
    bool isMood = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF221F26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isMood ? Icons.sentiment_very_satisfied : Icons.circle,
                  color: dotColor,
                  size: isMood ? 18 : 10,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1A171E),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFA441DC).withOpacity(0.8),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddChildButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _navigateToAddChildPage,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A171E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFA441DC).withOpacity(0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA441DC).withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Добавить ребенка',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


