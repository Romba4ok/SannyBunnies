import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/user/home/faq.dart';
import 'package:sannybunnies/pages/user/home/news/news.dart';
import 'package:sannybunnies/pages/user/home/news/detail_news.dart';
import 'package:sannybunnies/pages/user/home/reviews.dart';
import 'package:sannybunnies/pages/user/home/menu/menu.dart';
import 'package:sannybunnies/pages/user/home/groups.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/user/home_service.dart';
import 'dart:typed_data';

import 'package:sannybunnies/services/user/profile_service.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

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
        if (cachedProfile != null) _isLoading = false;
      });
    }

    ProfileService.instance.profileStream(currentUser.uid).listen((data) {
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userData == null) {
      return const LoadPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 25, 16, 0),
                child: _buildMainContent(),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _menuBtn(context, 'Вопросы', 'мы собрали самые частые вопросы и честно на них ответили', 'assets/images/home/faq_container.png', const FAQPage()),
                  _menuBtn(context, 'События', 'волшебное события в детском саду, созданное с большой любовью, ', 'assets/images/home/news_container.png', const NewsPage()),
                  _menuBtn(context, 'Отзывы', 'искренние отзывы родителей о нашем детском саде', 'assets/images/home/reviews.png', const ReviewsPage()),
                  _menuBtn(context, 'Меню\nпитания', 'полноценное и сбалансированное меню питания для наших малышей', 'assets/images/home/menu_container.png', const MenuPage()),
                ],
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Center( 
                  child: SizedBox(
                    
                    
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    child: AspectRatio(
                      aspectRatio: 0.95, 
                      child: _menuBtn(
                        context,
                        'Группы',
                        'Территория\nрадости \nи открытий',
                        'assets/images/home/groups_container.png',
                        const GroupsPage(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: HomeService.instance.firstNewsItemStream(),
      builder: (context, newsSnapshot) {
        final news = newsSnapshot.data;
        final title = news?['headline'] ?? 'Загрузка';
        final description = news?['body'] ?? '';
        final imageUrl = news?['photo_url'];

        return StreamBuilder<Map<String, dynamic>?>(
          stream: HomeService.instance.kindergartenInfoStream(),
          builder: (context, kgSnapshot) {
            final kg = kgSnapshot.data;
            final address = kg?['address'] ?? 'Загрузка';
            final schedule = kg?['schedule'] ?? 'Загрузка';

            return Column(
              children: [
                _buildNewsCard(title, description, imageUrl, news),
                const SizedBox(height: 15),
                _buildSummaryCard(address, schedule),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNewsCard(String title, String desc, String? url, Map<String, dynamic>? newsData) {
    return GestureDetector(
      onTap: () {
        if (newsData != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DetailNewsDialog(news: newsData),
          );
        }
      },
      child: Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF1B191B),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (url != null && url.isNotEmpty)
              FutureBuilder<List<int>?>(
                future: ProfileService.instance.getCachedPhotoBytes(url),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.done && snap.data != null) {
                    return Image.memory(
                      Uint8List.fromList(snap.data!),
                      width: double.infinity,
                      height: 230,
                      fit: BoxFit.cover,
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                      return Container(
                      width: double.infinity,
                      height: 230,
                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFFA441DC)),
                      ),
                    );
                  }
                  return Image.network(url, width: double.infinity, height: 230, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[900]));
                },
              )
            else
              Container(color: Colors.grey[900]),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Новинка',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                      const Color.fromRGBO(0, 0, 0, 0.9),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.7),
                      fontSize: 12,
                      height: 1.3,
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
    );
  }

  Widget _buildSummaryCard(String address, String schedule) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFA441DC),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCol('Адрес:', address, 0),
              _infoCol('График:', schedule, 20),
              _infoCol('Педагоги:', 'Грамотные,\nзаботливые', 0),
            ],
          ),
        ),
        Positioned(
          top: -30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF7941D),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 4),
            ),
            child: const Text(
              'Краткая сводка',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCol(String t, String v, double height) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: height),
          Text(
            t,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            v,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBtn(
    BuildContext ctx,
    String t,
    String s,
    String imagePath,
    Widget page, {

    bool isCenter = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (c) => page)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
                    colors: [
                const Color.fromRGBO(0, 0, 0, 0.1),
                const Color.fromRGBO(0, 0, 0, 0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment:  MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 0.85),
                  fontSize: 15,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}


