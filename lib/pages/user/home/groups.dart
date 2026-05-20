import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/user/dashboard_service.dart';
import 'package:sannybunnies/services/user/groups_service.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class SmallVisualCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String backgroundAsset;
  final bool isElevated;
  final double width;
  final double height;
  final List<Color> gradientColors;
  final TextAlign textAlign;

  const SmallVisualCard({
    Key? key,
    required this.group,
    required this.backgroundAsset,
    this.isElevated = false,
    this.width = 100,
    this.height = 150,
    this.gradientColors = const [Colors.transparent, Colors.transparent],
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = group['name']?.toString() ?? 'Группа';
    final ageFrom = group['age_from']?.toString() ?? '0';
    final ageTo = group['age_to']?.toString() ?? '0';

    CrossAxisAlignment crossAxis;
    switch (textAlign) {
      case TextAlign.center:
        crossAxis = CrossAxisAlignment.center;
        break;
      case TextAlign.end:
        crossAxis = CrossAxisAlignment.end;
        break;
      default:
        crossAxis = CrossAxisAlignment.start;
    }

    return Transform.translate(
      offset: Offset(0, isElevated ? -18 : 0),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color.fromRGBO(0, 0, 0, 0.28),
          ),
          child: Column(
            crossAxisAlignment: crossAxis,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'с $ageFrom до $ageTo лет',
                textAlign: textAlign,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoBlock extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const InfoBlock({
    Key? key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(45),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  Map<String, dynamic>? _userData;

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

  Color _getGroupColor(String name) {
    name = name.toLowerCase();
    if (name.contains('младшая')) return const Color(0xFFC32A5A);
    if (name.contains('средняя')) return const Color(0xFFE68D44);
    if (name.contains('старшая')) return const Color(0xFF6E78D1);
    return Colors.grey;
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
        stream: GroupsService.instance.groupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadPage();
          }
          final groups = snapshot.data ?? [];
          final sortedGroups = List<Map<String, dynamic>>.from(groups);
          sortedGroups.sort((a, b) {
            final ageA = int.tryParse(a['age_from']?.toString() ?? '') ?? 0;
            final ageB = int.tryParse(b['age_from']?.toString() ?? '') ?? 0;
            if (ageA != ageB) return ageA.compareTo(ageB);
            return (a['name']?.toString() ?? '')
                .compareTo(b['name']?.toString() ?? '');
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sortedGroups.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Возрастные группы',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              if (index == 1) {
                return _buildTopVisual(sortedGroups);
              }
              final group = sortedGroups[index - 2];
              return _buildGroupCard(group);
            },
          );
        },
      ),
    );
  }

  Widget _buildTopVisual(List<Map<String, dynamic>> groups) {
    final displayedGroups = List<Map<String, dynamic>>.from(groups.take(3));
    while (displayedGroups.length < 3) {
      displayedGroups.add({'name': 'Группа', 'age_from': '0', 'age_to': '0'});
    }

    final backgrounds = [
      'assets/images/groups/background_container1.png',
      'assets/images/groups/background_container2.png',
      'assets/images/groups/background_container3.png',
    ];

    return Column(
      children: [
        SizedBox(
          height: 400, 
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/groups/background_groups.png',
                      ),
                      fit: BoxFit.fill, 
                    ),
                  ),
                ),
              ),

              
              Positioned(
                left: 30,
                top: 120, 
                child: SmallVisualCard(
                  group: displayedGroups[0],
                  backgroundAsset: backgrounds[0],
                  isElevated: false,
                  width: 108,
                  height: 150,
                  gradientColors: const [Color(0xFFFF0057), Color(0xFFDD325F)],
                  textAlign: TextAlign.start,
                ),
              ),

              
              Positioned(
                right: 30,
                top: 120,
                child: SmallVisualCard(
                  group: displayedGroups[2],
                  backgroundAsset: backgrounds[2],
                  isElevated: false,
                  width: 108,
                  height: 150,
                  gradientColors: const [Color(0xFF929DF2), Color(0xFF4255E2)],
                  textAlign: TextAlign.end,
                ),
              ),

              
              
              Positioned(
                top: 60, 
                child: SmallVisualCard(
                  group: displayedGroups[1],
                  backgroundAsset: backgrounds[1],
                  isElevated: true,
                  width: 130,
                  height: 185,
                  gradientColors: const [Color(0xFFFFB94F), Color(0xFFFF6A00)],
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] ?? '';
    final childrenCount = (group['children_uids'] as List?)?.length ?? 0;
    final teachersCount = (group['teacher_uids'] as List?)?.length ?? 0;
    final color = _getGroupColor(name);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              40,
            ), 
          ),
          child: Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32, 
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle
                      .italic, 
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InfoBlock(
                    value: childrenCount.toString(),
                    label: 'Детей в группе',
                    icon: Icons.face_retouching_natural,
                    iconColor: const Color(0xFFFFD572),
                  ),
                  const SizedBox(width: 60),
                  InfoBlock(
                    value: teachersCount.toString(),
                    label: 'Педагог',
                    icon: Icons.school,
                    iconColor: const Color(0xFF4267B2),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10,),
      ],
    );
  }

  

}


