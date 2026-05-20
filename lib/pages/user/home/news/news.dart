import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/user/home/news/detail_news.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/news_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _signOut() async {
    await LoginService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
          (route) => false,
    );
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedProfile =
        await ProfileService.instance.loadCachedProfile(currentUser.uid);
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

  void _showNewsDetail(Map<String, dynamic> news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailNewsDialog(news: news),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _userData?['photoUrl'] as String?;
    final userName = _userData?['name'] as String? ?? 'Пользователь';

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      appBar: DashboardAppBarService.buildAppBar(
        context: context,
        onLogout: _signOut,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NewsService.instance.newsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadPage();
          }
          final newsList = snapshot.data ?? [];
          final sortedNews = List<Map<String, dynamic>>.from(newsList);
          sortedNews.sort((a, b) {
            DateTime? toDateTime(dynamic value) {
              if (value == null) return null;
              if (value is DateTime) return value;
              if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
              if (value is String) return DateTime.tryParse(value);
              if (value.runtimeType.toString().contains('Timestamp')) {
                try {
                  return (value as dynamic).toDate() as DateTime;
                } catch (_) {
                  return null;
                }
              }
              return null;
            }

            final createdA = toDateTime(a['createdAt']);
            final createdB = toDateTime(b['createdAt']);
            if (createdA != null && createdB != null) {
              return createdB.compareTo(createdA);
            }
            if (createdA != null) return -1;
            if (createdB != null) return 1;
            return (b['headline']?.toString() ?? '')
                .compareTo(a['headline']?.toString() ?? '');
          });

          return CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'События',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildNewsCard(sortedNews[index]);
                    },
                    childCount: sortedNews.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final String headline = news['headline'] ?? '';
    final String body = news['body'] ?? '';
    final String photoUrl = news['photo_url'] ?? '';

    return GestureDetector(
      onTap: () => _showNewsDetail(news),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1B191B),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl.isNotEmpty)
              DashboardAppBarService.buildCachedImage(
                photoUrl,
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.grey[900]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(0, 0, 0, 0.1),
                    const Color.fromRGBO(0, 0, 0, 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Colors.white70,
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

}


