import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sannybunnies/services/user/profile_service.dart';


class DashboardAppBarService {
  static final DashboardAppBarService _instance =
      DashboardAppBarService._internal();

  factory DashboardAppBarService() {
    return _instance;
  }

  DashboardAppBarService._internal();

  
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    VoidCallback? onLogout,
    VoidCallback? onNotifications,
    bool showNotificationButton = false,
  }) {
    return _DashboardAppBarWidget(
      onLogout: onLogout,
      onNotifications: onNotifications,
      showNotificationButton: showNotificationButton,
    );
  }

  static Widget buildCachedImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool showLoadingIndicator = true,
  }) {
    return _DashboardCachedImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      showLoadingIndicator: showLoadingIndicator,
    );
  }
}

class _DashboardAppBarWidget extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;
  final bool showNotificationButton;

  const _DashboardAppBarWidget({
    Key? key,
    this.onLogout,
    this.onNotifications,
    this.showNotificationButton = false,
  }) : super(key: key);

  @override
  State<_DashboardAppBarWidget> createState() => _DashboardAppBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DashboardAppBarWidgetState extends State<_DashboardAppBarWidget> {
  Map<String, dynamic>? _userData;
  Uint8List? _photoBytes;
  bool _isPhotoLoading = false;
  String? _photoUrlForCachedBytes;

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
    if (!mounted) return;

    setState(() {
      _userData = cachedProfile;
    });
    _prepareProfilePhoto(cachedProfile?['photoUrl'] as String?);

    ProfileService.instance.profileStream(currentUser.uid).listen((data) {
      if (!mounted) return;
      setState(() {
        _userData = data;
      });
      _prepareProfilePhoto(data['photoUrl'] as String?);
    });
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

  Widget _buildCachedProfileImage(
    String? photoUrl, {
    double width = 40,
    double height = 40,
  }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey,
        child: const Icon(Icons.person, size: 20, color: Colors.white30),
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
          child: const Icon(Icons.person, size: 20, color: Colors.white30),
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
      child: const Icon(Icons.person, size: 20, color: Colors.white30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['name'] as String? ?? 'Пользователь';
    final photoUrl = _userData?['photoUrl'] as String?;

    return AppBar(
      backgroundColor: const Color(0xFF131010),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: photoUrl?.isNotEmpty == true
                  ? _buildCachedProfileImage(photoUrl, width: 40, height: 40)
                  : Container(
                      color: Colors.grey,
                      child: const Icon(
                        Icons.person,
                        size: 24,
                        color: Colors.white30,
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
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Выйти',
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _DashboardCachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingIndicator;

  const _DashboardCachedImage({
    Key? key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    return FutureBuilder<List<int>?>(
      future: ProfileService.instance.getCachedPhotoBytes(url!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => errorWidget ?? _defaultPlaceholder(),
          );
        }

        if (showLoadingIndicator && snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFA441DC)),
            ),
          );
        }

        return errorWidget ?? placeholder ?? _defaultPlaceholder();
      },
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey,
      child: const Icon(Icons.person, color: Colors.white30),
    );
  }
}


