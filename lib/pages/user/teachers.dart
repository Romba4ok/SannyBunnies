import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/user/profile_service.dart';
import 'package:sannybunnies/services/user/teachers_service.dart';

class UserTeachersPage extends StatefulWidget {
  const UserTeachersPage({Key? key}) : super(key: key);

  @override
  State<UserTeachersPage> createState() => _UserTeachersPageState();
}

class _UserTeachersPageState extends State<UserTeachersPage> {
  Map<String, dynamic>? _userData;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedProfile = await ProfileService.instance.loadCachedProfile(
      currentUser.uid,
    );
    if (mounted) {
      setState(() {
        _userData = cachedProfile;
        _isProfileLoading = cachedProfile == null;
      });
    }

    ProfileService.instance.profileStream(currentUser.uid).listen((data) {
      if (mounted) {
        setState(() {
          _userData = data;
          _isProfileLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: TeachersService.instance.teachersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadPage();
          }
          final teachers = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Воспитатели',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Профессиональная команда заботливых специалистов для ваших детей.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                ...teachers
                    .map((teacher) => _buildTeacherCard(teacher))
                    .toList(),
                const SizedBox(height: 20),
                _buildCertificationBanner(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final name = teacher['name'] ?? '';
    final position = teacher['position'] ?? '';
    final description = teacher['description'] ?? '';
    final photoUrl = teacher['photo_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B191B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF212020),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                          ? _buildCachedImage(photoUrl, width: 90, height: 90)
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA441DC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'топ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA441DC), Color(0xFF6B1DAE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          const Icon(Icons.star_outline, color: Color(0xFFB087B5), size: 50),
          const SizedBox(height: 10),
          Text(
            'Все наши сотрудники сертифицированы',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Мы ежегодно проходим аттестацию качества образования',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedImage(String url, {double? width, double? height}) {
    return FutureBuilder<List<int>?>(
      future: ProfileService.instance.getCachedPhotoBytes(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
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
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFA441DC),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey,
            child: const Icon(Icons.person, color: Colors.white30),
          ),
        );
      },
    );
  }
}


