import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/pages/user/profile/children_tab.dart';
import 'package:sannybunnies/pages/user/profile/request_tab.dart';
import 'package:sannybunnies/pages/user/profile/settings_tab.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/user/profile_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _isUploadingPhoto = false;
  bool _isProfileLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _cachedUserData;
  Uint8List? _photoBytes;
  bool _isPhotoLoading = false;
  String? _photoUrlForCachedBytes;
  List<Map<String, dynamic>> _children = [];
  bool _isChildrenLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _childrenSubscription;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  String _kindergartenPhone = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadProfileData();
    _loadChildren();
    _loadKindergartenData();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _childrenSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedProfile = await ProfileService.instance.loadCachedProfile(
      currentUser.uid,
    );
    if (!mounted) return;

    setState(() {
      _cachedUserData = cachedProfile;
      _isProfileLoading = cachedProfile == null;
    });
    _prepareProfilePhoto(cachedProfile?['photoUrl'] as String?);

    _profileSubscription = ProfileService.instance
        .profileStream(currentUser.uid)
        .listen(
          (data) {
        if (!mounted) return;
        setState(() {
          _userData = data;
          _isProfileLoading = false;
        });
        _prepareProfilePhoto(data['photoUrl'] as String?);
      },
      onError: (error) {
        if (!mounted) return;
        if (_cachedUserData == null) {
          setState(() {
            _isProfileLoading = false;
          });
        }
      },
    );
  }

  Future<void> _loadChildren() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedChildren = await ProfileService.instance.loadCachedChildren(
      currentUser.uid,
    );
    if (!mounted) return;
    setState(() {
      _children = cachedChildren;
      _isChildrenLoading = cachedChildren.isEmpty;
    });

    _enrichChildrenWithGroupInfo();

    _childrenSubscription = ProfileService.instance
        .childrenStream(currentUser.uid)
        .listen(
          (children) {
        if (!mounted) return;
        setState(() {
          _children = children;
          _isChildrenLoading = false;
        });
        _enrichChildrenWithGroupInfo();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isChildrenLoading = false;
        });
      },
    );
  }

  Future<void> _enrichChildrenWithGroupInfo() async {
    if (_children.isEmpty) return;
    final Map<String, Map<String, dynamic>> groupCache = {};
    final Map<String, String> teacherNameCache = {};

    final Set<String> groupIds = _children
        .map((c) => c['group_id'] as String?)
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toSet();

    for (final gid in groupIds) {
      final group = await ProfileService.instance.fetchGroupById(gid);
      if (group != null) {
        groupCache[gid] = group;
        final List<dynamic>? teachers = group['teacher_uids'] as List<dynamic>?;
        if (teachers != null && teachers.isNotEmpty) {
          final firstTeacherUid = teachers.first as String?;
          if (firstTeacherUid != null && firstTeacherUid.isNotEmpty) {
            final tName = await ProfileService.instance.fetchUserNameById(firstTeacherUid);
            if (tName != null) teacherNameCache[firstTeacherUid] = tName;
          }
        }
      }
    }

    var updated = false;
    final newChildren = _children.map((child) {
      final cloned = Map<String, dynamic>.from(child);
      final gid = cloned['group_id'] as String?;
      if (gid != null && gid.isNotEmpty && groupCache.containsKey(gid)) {
        final g = groupCache[gid]!;
        final gName = g['name'] as String? ?? '';
        cloned['group'] = gName;
        final List<dynamic>? teachers = g['teacher_uids'] as List<dynamic>?;
        String nannyName = 'Не назначен';
        if (teachers != null && teachers.isNotEmpty) {
          final ft = teachers.first as String?;
          if (ft != null && teacherNameCache.containsKey(ft)) {
            nannyName = teacherNameCache[ft]!;
          }
        }
        cloned['nanny'] = nannyName;
        updated = true;
      }
      return cloned;
    }).toList();

    if (updated && mounted) {
      setState(() {
        _children = newChildren;
      });
    }
  }

  Future<void> _loadKindergartenData() async {
    try {
      final info = await ProfileService.instance.getKindergartenInfo();
      if (info != null && mounted) {
        setState(() {
          _kindergartenPhone = info['phone']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading kindergarten info: $e');
    }
  }

  String _normalizePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '';
    if (clean.length == 11 && clean.startsWith('8')) {
      return '7${clean.substring(1)}';
    }
    if (clean.length == 11 && clean.startsWith('7')) {
      return clean;
    }
    if (clean.length == 10) {
      return '7$clean';
    }
    return clean;
  }

  Future<void> _openPhoneCall() async {
    if (_kindergartenPhone.isEmpty) return;
    final normalized = _normalizePhone(_kindergartenPhone);
    if (normalized.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: '+$normalized');
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть звонок')),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    if (_kindergartenPhone.isEmpty) return;
    final normalized = _normalizePhone(_kindergartenPhone);
    if (normalized.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$normalized');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Установите WhatsApp или проверьте интернет'),
        ),
      );
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isUploadingPhoto) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      await ProfileService.instance.uploadProfilePhoto(
        currentUser.uid,
        bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Фото профиля обновлено')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  void _prepareProfilePhoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      _photoUrlForCachedBytes = null;
      _photoBytes = null;
      _isPhotoLoading = false;
      return;
    }

    if (_photoUrlForCachedBytes != photoUrl) {
      _photoUrlForCachedBytes = photoUrl;
      _photoBytes = null;
      _loadCachedPhotoBytes(photoUrl);
    }
  }

  Future<void> _loadCachedPhotoBytes(String photoUrl) async {
    if (_isPhotoLoading && _photoUrlForCachedBytes == photoUrl) return;
    setState(() {
      _isPhotoLoading = true;
    });

    final bytes = await ProfileService.instance.getCachedPhotoBytes(photoUrl);
    if (!mounted || _photoUrlForCachedBytes != photoUrl) return;

    setState(() {
      _photoBytes = bytes != null ? Uint8List.fromList(bytes) : null;
      _isPhotoLoading = false;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await LoginService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
          (route) => false,
    );
  }

  bool get _canChangePassword {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.providerData.any(
          (provider) => provider.providerId == 'password',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF131010),
        body: Center(
          child: Text(
            'Пользователь не найден',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final effectiveData = _userData ?? _cachedUserData;
    final isInitialLoading = effectiveData == null && _isProfileLoading;

    if (effectiveData == null && !isInitialLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF131010),
        body: Center(
          child: Text(
            'Пользователь не найден',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final userName = effectiveData?['name'] as String? ?? 'Пользователь';
    final userEmail = effectiveData?['email'] as String? ?? '';
    final userPhone = effectiveData?['phone'] as String? ?? '';
    final photoUrl = effectiveData?['photoUrl'] as String?;
    final notificationsEnabled =
        effectiveData?['notificationsEnabled'] as bool? ?? true;

    if (isInitialLoading) {
      return const LoadPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFA441DC),
                            width: 4,
                          ),
                        ),
                        child: ClipOval(
                          child: photoUrl?.isNotEmpty == true
                              ? _buildCachedProfileImage(
                            photoUrl,
                            width: 120,
                            height: 120,
                          )
                              : Container(
                            color: Colors.grey,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                      if (_isUploadingPhoto)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black38,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFA441DC),
                              ),
                            ),
                          ),
                        ),
                      if (_selectedTab == 1)
                        GestureDetector(
                          onTap: _pickAndUploadProfileImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFA441DC),
                              border: Border.all(
                                color: const Color(0xFF131010),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Связь с администрацией',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildContactButton(
                          iconPath: 'assets/images/profile/phone.svg',
                          label: 'Позвонить',
                          onTap: _openPhoneCall,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContactButton(
                          iconPath: 'assets/images/profile/message.svg',
                          label: 'Написать',
                          onTap: _openWhatsApp,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTab('дети', "assets/images/profile/children.svg", 0),
                    _buildTab(
                      'настройки',
                      "assets/images/profile/settings.svg",
                      1,
                    ),
                    _buildTab(
                      'заявка',
                      "assets/images/profile/application.svg",
                      2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            IndexedStack(
              index: _selectedTab,
              children: [
                ChildrenTab(
                  isChildrenLoading: _isChildrenLoading,
                  children: _children,
                ),
                SettingsTab(
                  uid: currentUser.uid,
                  userName: userName,
                  userEmail: userEmail,
                  userPhone: userPhone,
                  notificationsEnabled: notificationsEnabled,
                  canChangePassword: _canChangePassword,
                  onSignOut: () => _signOut(context),
                ),
                RequestTab(
                  isChildrenLoading: _isChildrenLoading,
                  children: _children,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1B191B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA441DC),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
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

  Widget _buildCachedProfileImage(
      String? photoUrl, {
        double width = 120,
        double height = 120,
      }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey,
        child: const Icon(Icons.person, size: 24, color: Colors.white30),
      );
    }

    if (_photoBytes != null && _photoBytes!.isNotEmpty) {
      return Image.memory(
        _photoBytes!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey,
          child: const Icon(Icons.person, size: 24, color: Colors.white30),
        ),
      );
    }

    if (_isPhotoLoading) {
      return Container(
        width: width,
        height: height,
        color: Colors.black.withOpacity(0.2),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFA441DC)),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey,
      child: const Icon(Icons.person, size: 24, color: Colors.white30),
    );
  }

  Widget _buildTab(String label, String svgPath, int index) {
    final bool isSelected = _selectedTab == index;
    const Color activeColor = Color(0xFFA441DC);
    const Color inactiveColor = Colors.white70;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 9),
          SvgPicture.asset(
            svgPath,
            height: 15,
            width: 15,
            colorFilter: ColorFilter.mode(
              isSelected ? activeColor : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}


