import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class DetailMenuPage extends StatefulWidget {
  final Map<String, dynamic> menuItem;
  const DetailMenuPage({Key? key, required this.menuItem}) : super(key: key);

  @override
  State<DetailMenuPage> createState() => _DetailMenuPageState();
}

class _DetailMenuPageState extends State<DetailMenuPage> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _signOut() async {
    await LoginService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
          (route) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    final item = widget.menuItem;
    final List<dynamic> ingredients = item['ingredients'] ?? [];
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFA441DC),
      body: Stack(
        children: [
          Container(color: const Color(0xFFA441DC)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  Text(
                    item['meal'] ?? item['title'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'КБЖУ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 400,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF131010),
                borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ингредиенты:',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: ingredients.map((ing) => _buildIngredientChip(ing.toString())).toList(),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Описание',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['description'] ?? 'Описание отсутствует',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildKbjuRow('Калории:', '~${item['kcal'] ?? '-'} ккал'),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 230,
            left: media.width * 0.12,
            right: media.width * 0.12,
            child: _buildImageSection(item['photo_url']),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String? photoUrl) {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.15), width: 10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? FutureBuilder<List<int>?>(
                future: ProfileService.instance.getCachedPhotoBytes(photoUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    return Image.memory(
                      Uint8List.fromList(snapshot.data!),
                      fit: BoxFit.cover,
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFFA441DC)),
                      ),
                    );
                  }
                  return Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.restaurant, size: 80, color: Colors.white24),
                  );
                },
              )
            : Container(
                color: Colors.grey[900],
                child: const Icon(Icons.restaurant, size: 80, color: Colors.white24),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final photoUrl = _userData?['photoUrl'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800]),
            child: ClipOval(
              child: photoUrl != null && (photoUrl as String).isNotEmpty
                  ? DashboardAppBarService.buildCachedImage(
                      photoUrl as String,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: Container(color: Colors.grey[800], child: const Icon(Icons.person, color: Colors.white)),
                      errorWidget: Container(color: Colors.grey[800], child: const Icon(Icons.person, color: Colors.white)),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Родитель', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                _userData?['name'] ?? '...',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Выйти',
          ),
        ],
      ),
    );
  }


  Widget _buildIngredientChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4B37),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Icon(Icons.flatware, color: Color(0xFFF7941D), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildKbjuRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}