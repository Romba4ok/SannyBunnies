import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/pages/user/interior/detail_interior.dart';
import 'package:sannybunnies/services/user/interior_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class UserInteriorPage extends StatefulWidget {
  const UserInteriorPage({Key? key}) : super(key: key);

  @override
  State<UserInteriorPage> createState() => _UserInteriorPageState();
}

class _UserInteriorPageState extends State<UserInteriorPage> {
  Map<String, dynamic>? _userData;
  bool _isProfileLoading = true;

  final List<Color> _glowColors = [
    const Color(0xFFFF4D94), 
    const Color(0xFFFF9933), 
    const Color(0xFF7C3AED), 
    const Color(0xFF33CC66), 
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedProfile =
        await ProfileService.instance.loadCachedProfile(currentUser.uid);
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
        stream: InteriorService.instance.interiorStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadPage();
          }
          final interiors = snapshot.data ?? [];

          return Container(
            width: double.infinity,
            height: double.infinity,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              itemCount: (interiors.length / 2).ceil(),
              itemBuilder: (context, rowIndex) {
                final int firstIndex = rowIndex * 2;
                final int secondIndex = firstIndex + 1;
                final bool isLeftWide = rowIndex % 2 == 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      
                      Expanded(
                        flex: isLeftWide ? 5 : 4,
                        child: SizedBox(
                          height: 180,
                          child: _buildInteriorCard(
                            interiors[firstIndex],
                            _glowColors[firstIndex % _glowColors.length],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      Expanded(
                        flex: isLeftWide ? 4 : 5,
                        child: secondIndex < interiors.length
                            ? SizedBox(
                                height: 180,
                                child: _buildInteriorCard(
                                  interiors[secondIndex],
                                  _glowColors[secondIndex % _glowColors.length],
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteriorCard(Map<String, dynamic> item, Color glowColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserInteriorDetailPage(interior: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: glowColor.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          item['name'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


