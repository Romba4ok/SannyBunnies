import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/authorization/auth_choice_page.dart';
import 'package:sannybunnies/pages/authorization/google_profile_completion_page.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/pages/prev_page.dart';
import 'package:sannybunnies/pages/teacher/dashboard.dart';
import 'package:sannybunnies/pages/teacher/prev_Page.dart';
import 'package:sannybunnies/pages/user/dashboard.dart';
import 'package:sannybunnies/services/notification_topic_service.dart';
import 'package:sannybunnies/services/user/groups_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class AuthWrapper extends StatefulWidget {
  final bool seenPreview;

  const AuthWrapper({Key? key, this.seenPreview = true}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _currentUid;
  String? _currentRole;
  bool _isConfiguringTopics = false;

  Future<void> _configureTopics(
    String uid,
    String role,
    bool notificationsEnabled,
  ) async {
    if (_isConfiguringTopics) {
      print('[AuthWrapper] Конфигурация уже запущена, пропускаю');
      return;
    }

    if (!notificationsEnabled) {
      print('[AuthWrapper] Уведомления отключены, очищаю подписки');
      await _clearSubscriptions();
      return;
    }

    if (_currentUid == uid && _currentRole == role) {
      print('[AuthWrapper] Конфигурация уже выполнена для $uid/$role');
      return;
    }

    _currentUid = uid;
    _currentRole = role;
    _isConfiguringTopics = true;

    print('[AuthWrapper] Начинаю конфигурацию подписок для $uid (роль: $role)');

    try {
      final groupIds = role == 'teacher'
          ? await GroupsService.instance.fetchTeacherGroupIds(uid)
          : await ProfileService.instance.getChildGroupIds(uid);

      print('[AuthWrapper] Загруженные groupIds: $groupIds');

      await NotificationTopicService.instance.updateSubscriptions(
        uid: uid,
        role: role,
        groupIds: groupIds,
      );

      print('[AuthWrapper] ✓ Конфигурация подписок завершена');
    } catch (error) {
      print('[AuthWrapper] ✗ Ошибка настройки подписок на темы: $error');
    } finally {
      _isConfiguringTopics = false;
    }
  }

  Future<void> _clearSubscriptions() async {
    await NotificationTopicService.instance.clearSubscriptions();
    _currentUid = null;
    _currentRole = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.seenPreview) {
      return const PrevPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadPage();
        }

        final user = authSnapshot.data;
        if (user == null) {
          if (_currentUid != null) {
            _clearSubscriptions();
          }
          return const AuthChoicePage();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: ProfileService.instance.getCachedOrRemoteProfile(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadPage();
            }

            if (roleSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Ошибка получения роли: ${roleSnapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = roleSnapshot.data;
            if (data == null || data.isEmpty) {
              return const GoogleProfileCompletionPage();
            }

            final role = data['role'] as String?;
            if (role != null) {
              final notificationsEnabled =
                  data['notificationsEnabled'] as bool? ?? true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _configureTopics(
                  user.uid,
                  role,
                  notificationsEnabled,
                ),
              );
            }

            if (role == 'teacher') {
              return const TeacherPrevPage();
            }

            return const UserNavigationPage();
          },
        );
      },
    );
  }
}
