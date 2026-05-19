import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class RequestTab extends StatefulWidget {
  final bool isChildrenLoading;
  final List<Map<String, dynamic>> children;

  const RequestTab({
    Key? key,
    required this.isChildrenLoading,
    required this.children,
  }) : super(key: key);

  @override
  State<RequestTab> createState() => _RequestTabState();
}

class _RequestTabState extends State<RequestTab> {
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

  Future<void> _toggleChildRequestStatus(Map<String, dynamic> child) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final childId = child['id'] as String?;
    if (childId == null) return;

    final bool? currentRequestStatus = child['requestStatus'] as bool?;

    if (currentRequestStatus == true) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          title: const Text('Отчислить ребенка?'),
          content: const Text(
            'Вы действительно хотите отчислить этого ребенка?',
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
                'Отчислить',
                style: TextStyle(color: Color(0xFFFF5A5F)),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      final message = await ProfileService.instance.toggleChildRequestStatus(
        currentUser.uid,
        childId,
        currentRequestStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                'У вас пока нет детей для подачи заявки',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
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
              _buildExpandedRequestCard(widget.children[index]),
            ],
            const SizedBox(height: 20),
          ],
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

  Widget _buildExpandedRequestCard(Map<String, dynamic> child) {
    final photoUrl = child['photoUrl'] as String?;
    final birthDate = child['birthDate'] as String? ?? 'Не указано';
    final nanny = child['nanny'] as String? ?? 'Не назначен';
    final group = child['group'] as String? ?? 'Не назначена';

    final bool? requestStatus = child['requestStatus'] as bool?;
    final String statusText = requestStatus == true
        ? 'Зачислен(а)'
        : requestStatus == null
        ? 'На рассмотрении'
        : 'Не зачислен(а)';

    final features = List<String>.from(
      child['features'] as List<dynamic>? ?? [],
    ).where((f) => f.trim().isNotEmpty).toList();

    final bool isEnrolled = requestStatus == true;
    final bool isReviewing = requestStatus == null;
    final String buttonLabel = isEnrolled
        ? 'Отчислиться'
        : isReviewing
        ? 'Отменить заявку'
        : 'Отправить заявку на зачисление';

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
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? FutureBuilder<List<int>?>(
                            future: ProfileService.instance.getCachedPhotoBytes(
                              photoUrl,
                            ),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                      ConnectionState.done &&
                                  snap.data != null) {
                                return Image.memory(
                                  Uint8List.fromList(snap.data!),
                                  fit: BoxFit.cover,
                                );
                              }
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  color: Colors.black.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFA441DC),
                                    ),
                                  ),
                                );
                              }
                              return Image.network(photoUrl, fit: BoxFit.cover);
                            },
                          )
                        : Container(
                            color: Colors.grey,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white30,
                              size: 40,
                            ),
                          ),
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
                _buildInfoRow('Статус', statusText),
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
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _toggleChildRequestStatus(child),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
}
