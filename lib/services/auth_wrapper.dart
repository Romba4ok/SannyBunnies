import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/authorization/auth_choice_page.dart';
import 'package:sannybunnies/pages/authorization/google_profile_completion_page.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/pages/prev_page.dart';
import 'package:sannybunnies/pages/teacher/dashboard.dart';
import 'package:sannybunnies/pages/teacher/prev_Page.dart';
import 'package:sannybunnies/pages/user/dashboard.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class AuthWrapper extends StatelessWidget {
  final bool seenPreview;

  const AuthWrapper({Key? key, this.seenPreview = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!seenPreview) {
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
