import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/user/faq_service.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  Map<String, dynamic>? _userData;

  final List<Color> _bubbleColors = [
    const Color(0xFFFF5B8D), 
    const Color(0xFFFF8A48), 
    const Color(0xFF8E8CFE), 
    const Color(0xFF00C566), 
  ];

  final List<String> _bunnyAssets = [
    'assets/images/faq/sunny_1.png',
    'assets/images/faq/sunny_2.png',
    'assets/images/faq/sunny_3.png',
    'assets/images/faq/sunny_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedProfile = await ProfileService.instance.loadCachedProfile(currentUser.uid);
    if (mounted) {
      setState(() {
        _userData = cachedProfile;
      });
    }

    ProfileService.instance.profileStream(currentUser.uid).listen((data) {
      if (mounted) {
        setState(() {
          _userData = data;
        });
      }
    });
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
    final userName = _userData?['name'] as String? ?? 'Пользователь';

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: DashboardAppBarService.buildCachedImage(
                  photoUrl,
                  width: 40,
                  height: 40,
                  placeholder: Container(
                    color: Colors.grey,
                    child: const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Родитель',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Stack(
        children: [
          
          Positioned.fill(
            child: Image.asset(
              'assets/images/faq/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FaqService.instance.faqStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadPage();
                      }
                      final faqList = snapshot.data ?? [];
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: faqList.length + 1, 
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildTitle();
                          }
                          final itemIndex = index - 1;
                          return _buildFaqItem(faqList[itemIndex], itemIndex);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FAQ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 15),
            
            Container(
              width: 4,
              height: 70, 
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E8CFE), Color(0xFFA441DC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 15),
            
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Часто',
                  style: TextStyle(color: Colors.white, fontSize: 20, height: 1.1),
                ),
                Text(
                  'задаваемые',
                  style: TextStyle(color: Colors.white, fontSize: 20, height: 1.1),
                ),
                Text(
                  'вопросы',
                  style: TextStyle(
                    color: Color(0xFFB148F0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> item, int index) {
    final bool isEven = index % 2 == 0;
    final Color color = _bubbleColors[index % _bubbleColors.length];
    final String bunnyAsset = _bunnyAssets[index % _bunnyAssets.length];
    
    final bubble = Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['question'] ?? '',
              textAlign: isEven ? TextAlign.left : TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['answer'] ?? '',
              textAlign: isEven ? TextAlign.left : TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );

    final bunny = Expanded(
      flex: 2,
      child: Image.asset(
        bunnyAsset,
        height: 120,
        alignment: isEven ? Alignment.centerRight : Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white30, size: 50),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isEven ? [bubble, const SizedBox(width: 10), bunny] : [bunny, const SizedBox(width: 10), bubble],
      ),
    );
  }

}


