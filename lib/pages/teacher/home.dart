import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/teacher/profile_service_teacher.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: ProfileServiceTeacher.instance.teacherProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadPage();
          }

          final data = snapshot.data;
          final name = data?['name'] ?? 'Загрузка...';

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Image.asset(
                    'assets/images/home_teacher/container.png',
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school_outlined,
                      size: 200,
                      color: Color(0xFFA441DC),
                    ),
                  ),
                  const SizedBox(height: 40),

                  
                  const Text(
                    'Добро пожаловать!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),

                  
                  const Text(
                    'В личный кабинет детского сада',
                    style: TextStyle(
                      color: Color(0xFF6B429C),
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Солнечные зайки',
                    style: TextStyle(
                      color: Color(0xFF6B429C),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
