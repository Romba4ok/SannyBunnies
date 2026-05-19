import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class SettingsTab extends StatelessWidget {
  final String uid;
  final String userName;
  final String userEmail;
  final String userPhone;
  final bool notificationsEnabled;
  final bool canChangePassword;
  final VoidCallback onSignOut;

  const SettingsTab({
    Key? key,
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.notificationsEnabled,
    required this.canChangePassword,
    required this.onSignOut,
  }) : super(key: key);

  Future<void> _editUserName(BuildContext context) async {
    final userDoc = await ProfileService.instance.fetchRemoteProfile(uid);
    final currentName = userDoc?['name'] as String? ?? '';

    final nameController = TextEditingController(text: currentName);
    bool isLoading = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          title: const Text(
            'Редактировать имя',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите ваше имя',
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
                      setDialogState(() => isLoading = true);
                      try {
                        await ProfileService.instance.updateUserProfile(
                          uid,
                          {'name': nameController.text.trim()},
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Имя обновлено')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: Text(
                'Сохранить',
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

  Future<void> _editUserPhone(BuildContext context) async {
    final userDoc = await ProfileService.instance.fetchRemoteProfile(uid);
    final currentPhone = userDoc?['phone'] as String? ?? '';

    final phoneController = TextEditingController(text: currentPhone);
    bool isLoading = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          title: const Text(
            'Редактировать телефон',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите ваш номер телефона',
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
                      setDialogState(() => isLoading = true);
                      try {
                        await ProfileService.instance.updateUserProfile(
                          uid,
                          {'phone': phoneController.text.trim()},
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Телефон обновлен')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: Text(
                'Сохранить',
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

  Future<void> _changePassword(BuildContext context) async {
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
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пароли не совпадают')),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        if (!context.mounted) return;
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
                        if (currentUser == null || currentUser.email == null) {
                          throw 'Пользователь не найден';
                        }

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

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пароль успешно изменен'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
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

  Future<void> _showPasswordProviderNotice(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B191B),
        title: const Text('Сменить пароль невозможно'),
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

  Future<void> _toggleNotifications(BuildContext context, bool value) async {
    try {
      await ProfileService.instance.updateUserProfile(uid, {
        'notificationsEnabled': value,
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Личная информация',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C181E),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _buildInfoField(
                  label: 'Имя',
                  value: userName.isNotEmpty ? userName : 'Не указано',
                  onTap: () => _editUserName(context),
                ),
                const Divider(color: Colors.white12, height: 1, thickness: 1),
                _buildInfoField(
                  label: 'Электронная почта',
                  value: userEmail.isNotEmpty ? userEmail : 'Не указан',
                  onTap: () {},
                ),
                const Divider(color: Colors.white12, height: 1, thickness: 1),
                _buildInfoField(
                  label: 'Телефон',
                  value: userPhone.isNotEmpty ? userPhone : 'Не указан',
                  onTap: () => _editUserPhone(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Безопасность',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.lock,
            label: 'Сменить пароль',
            onTap: () => canChangePassword
                ? _changePassword(context)
                : _showPasswordProviderNotice(context),
            isArrow: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'Уведомления',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.notifications,
            label: 'Уведомления',
            onTap: () => _showNotificationsDialog(context),
            isArrow: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Выйти из системы'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFFA441DC),
                side: const BorderSide(color: Color(0xFFA441DC), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) async {
    PermissionStatus status = await Permission.notification.status;
    bool isGranted = status.isGranted;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1B191B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                  const Text('Статус',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  Switch(
                    value: isGranted,
                    activeColor: const Color(0xFFA441DC),
                    onChanged: (value) async {
                      if (value) {
                        PermissionStatus newStatus =
                            await Permission.notification.request();

                        if (newStatus.isPermanentlyDenied) {
                          openAppSettings();
                        }

                        setState(() {
                          isGranted = newStatus.isGranted;
                        });
                        if (newStatus.isGranted) {
                          if (!context.mounted) return;
                          await _toggleNotifications(context, true);
                        }
                      } else {
                        openAppSettings();
                        if (context.mounted) {
                          Navigator.pop(context);
                          await _toggleNotifications(context, false);
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
              child: const Text('Закрыть',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C181E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
            if (isArrow) const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
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
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}


