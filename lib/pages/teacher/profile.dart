import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sannybunnies/pages/load_page.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:sannybunnies/services/login_service.dart';
import 'package:sannybunnies/services/notification_topic_service.dart';
import 'package:sannybunnies/services/user/groups_service.dart';
import 'package:sannybunnies/services/teacher/profile_service_teacher.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({Key? key}) : super(key: key);

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  bool _isUploadingPhoto = false;
  bool _isProfileLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _cachedUserData;
  Uint8List? _photoBytes;
  bool _isPhotoLoading = false;
  String? _photoUrlForCachedBytes;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final cachedProfile = await ProfileServiceTeacher.instance
        .loadCachedProfile(currentUser.uid);
    if (!mounted) return;

    setState(() {
      _cachedUserData = cachedProfile;
      _isProfileLoading = cachedProfile == null;
    });
    _prepareProfilePhoto(cachedProfile?['photoUrl'] as String?);

    _profileSubscription = ProfileServiceTeacher.instance
        .teacherProfileStream(currentUser.uid)
        .listen(
          (data) {
            if (!mounted) return;
            if (data.isEmpty) return;
            setState(() {
              _userData = data;
              _isProfileLoading = false;
            });
            _prepareProfilePhoto(data['photoUrl'] as String?);
          },
          onError: (error) {
            if (!mounted) return;
            if (_cachedUserData == null) {
              setState(() => _isProfileLoading = false);
            }
          },
        );
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
    setState(() => _isPhotoLoading = true);

    final bytes = await ProfileServiceTeacher.instance.getCachedPhotoBytes(
      photoUrl,
    );
    if (!mounted || _photoUrlForCachedBytes != photoUrl) return;

    setState(() {
      _photoBytes = bytes != null ? Uint8List.fromList(bytes) : null;
      _isPhotoLoading = false;
    });
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

    setState(() => _isUploadingPhoto = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      await ProfileServiceTeacher.instance.uploadProfilePhoto(
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
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _editField(
    String fieldName,
    String title,
    String currentValue,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final controller = TextEditingController(text: currentValue);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите значение',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFA441DC)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFA441DC), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newValue = controller.text.trim();
                      if (newValue.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Значение не может быть пустым'),
                          ),
                        );
                        return;
                      }
                      if (newValue == currentValue) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Нет изменений')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await ProfileServiceTeacher.instance
                            .updateTeacherProfile(currentUser.uid, {
                              fieldName: newValue,
                            });
                        final updatedProfile = Map<String, dynamic>.from(
                          (_userData != null && _userData!.isNotEmpty)
                              ? _userData!
                              : (_cachedUserData ?? {}),
                        );
                        updatedProfile[fieldName] = newValue;
                        await ProfileServiceTeacher.instance.cacheProfile(
                          updatedProfile,
                          currentUser.uid,
                        );

                        if (!mounted) return;
                        setState(() {
                          _userData = updatedProfile;
                          _cachedUserData = updatedProfile;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Обновлено')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      } finally {
                        setDialogState(() => isSaving = false);
                      }
                    },
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: isSaving ? Colors.grey : const Color(0xFFA441DC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          title: const Text(
            'Сменить пароль',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Текущий пароль',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFA441DC)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFA441DC),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Новый пароль',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFA441DC)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFA441DC),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Подтвердите пароль',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFA441DC)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFA441DC),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пароли не совпадают')),
                        );
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Пароль должен быть не менее 6 символов',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null || currentUser.email == null)
                          throw 'Пользователь не найден';

                        final credential = EmailAuthProvider.credential(
                          email: currentUser.email!,
                          password: currentPasswordController.text,
                        );
                        await currentUser.reauthenticateWithCredential(
                          credential,
                        );
                        await currentUser.updatePassword(
                          newPasswordController.text,
                        );

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пароль успешно изменен'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().contains('wrong-password')
                                  ? 'Неверный текущий пароль'
                                  : 'Ошибка: $e',
                            ),
                          ),
                        );
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: Text(
                'Изменить',
                style: TextStyle(
                  color: isLoading ? Colors.grey : const Color(0xFFA441DC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordProviderNotice() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B191B),
        title: const Text(
          'Сменить пароль невозможно',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'У вас вход через Google, поэтому пароль менять здесь нельзя.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК', style: TextStyle(color: Color(0xFFA441DC))),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() async {
    PermissionStatus status = await Permission.notification.status;
    bool isGranted = status.isGranted;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Уведомления',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isGranted
                    ? 'Уведомления включены'
                    : 'Уведомления отключены в системе',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Статус',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Switch(
                    value: isGranted,
                    activeColor: const Color(0xFFA441DC),
                    onChanged: (value) async {
                      if (value) {
                        PermissionStatus newStatus = await Permission
                            .notification
                            .request();
                        if (newStatus.isPermanentlyDenied) openAppSettings();
                        setState(() => isGranted = newStatus.isGranted);
                        if (newStatus.isGranted) {
                          await _toggleNotifications(true);
                        }
                      } else {
                        openAppSettings();
                        if (mounted) {
                          Navigator.pop(context);
                          await _toggleNotifications(false);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      await ProfileServiceTeacher.instance.updateTeacherProfile(
        currentUser.uid,
        {'notificationsEnabled': value},
      );

      if (value) {
        final groupIds = await GroupsService.instance.fetchTeacherGroupIds(
          currentUser.uid,
        );
        await NotificationTopicService.instance.updateSubscriptions(
          uid: currentUser.uid,
          role: 'teacher',
          groupIds: groupIds,
        );
      } else {
        await NotificationTopicService.instance.clearSubscriptions();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  bool get _canChangePassword {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  Future<void> _signOut() async {
    await LoginService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfileLoading && _userData == null && _cachedUserData == null) {
      return const LoadPage();
    }

    final effectiveData = (_userData != null && _userData!.isNotEmpty)
        ? _userData
        : (_cachedUserData != null && _cachedUserData!.isNotEmpty
              ? _cachedUserData
              : null);
    if (effectiveData == null) {
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

    final name = effectiveData['name'] as String? ?? 'Учитель';
    final email = effectiveData['email'] as String? ?? '';
    final phone = effectiveData['phone'] as String? ?? '';
    final photoUrl = effectiveData['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
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
                          child: _buildCachedProfileImage(
                            photoUrl,
                            width: 120,
                            height: 120,
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
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Личная информация',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C181E),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    _buildInfoField(
                      'Имя',
                      name,
                      () => _editField('name', 'Редактировать имя', name),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildInfoField('Электронная почта', email, null),
                    const Divider(color: Colors.white12, height: 1),
                    _buildInfoField(
                      'Телефон',
                      phone,
                      () => _editField('phone', 'Редактировать телефон', phone),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Безопасность',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSettingsItem(
                Icons.lock_outline,
                'Сменить пароль',
                () => _canChangePassword
                    ? _changePassword()
                    : _showPasswordProviderNotice(),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Уведомления',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSettingsItem(
                Icons.notifications_none,
                'Уведомления',
                _showNotificationsDialog,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти из системы'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA441DC),
                    side: const BorderSide(
                      color: Color(0xFFA441DC),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
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
          width: width,
          height: height,
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

  Widget _buildInfoField(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF958DA1),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C181E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFA441DC), size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
