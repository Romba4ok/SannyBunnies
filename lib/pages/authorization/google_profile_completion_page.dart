import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sannybunnies/pages/user/dashboard.dart';
import '../../services/login_service.dart';

class GoogleProfileCompletionPage extends StatefulWidget {
  const GoogleProfileCompletionPage({Key? key}) : super(key: key);

  @override
  State<GoogleProfileCompletionPage> createState() => _GoogleProfileCompletionPageState();
}

class _GoogleProfileCompletionPageState extends State<GoogleProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7 ');
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name != null && name.isNotEmpty) {
      _nameController.text = name;
    }
    for (var node in [_nameFocus, _phoneFocus]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь не найден. Перезайдите.')));
      }
      setState(() => _loading = false);
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      await LoginService.instance.completeGoogleProfile(name: name, phone: phone);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserNavigationPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        final hasFocus = focusNode.hasFocus;
        final outerDecoration = hasError
            ? BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12))
            : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: hasFocus
                    ? const LinearGradient(colors: [Color(0xFF5A3CB1), Color(0xFF2E2C58)])
                    : const LinearGradient(colors: [Color(0xFF808080), Color(0xFF303030)]),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: outerDecoration,
              padding: const EdgeInsets.all(1),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFF0F0D0D)),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  inputFormatters: formatters,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    fieldState.didChange(value);
                    if (onChanged != null) onChanged(value);
                  },
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white54),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                    suffixIcon: suffix,
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(fieldState.errorText ?? '', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  height: size.height * 0.24,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(image: AssetImage('assets/images/loginPage/logo.png'), fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const Text(
                        'Добро пожаловать',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Чтобы продолжить введите данные',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              hint: 'ФИО',
                              validator: (value) => value == null || value.trim().isEmpty ? 'ФИО' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              hint: 'Ваш номер телефона',
                              keyboardType: TextInputType.phone,
                              formatters: [_PhoneFormatter()],
                              validator: (value) => value != null && value.length < 18 ? 'Ваш номер телефона' : null,
                              onChanged: (value) {
                                final digits = value.replaceAll(RegExp(r'\D'), '');
                                if (digits.length <= 11) {
                                  final formatted = _formatPhone(digits);
                                  if (formatted != value) {
                                    _phoneController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 160),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA441DC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Продолжить', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Нажимая кнопку, вы соглашаетесь с ',
                                    style: TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                  TextSpan(
                                    text: 'Политикой конфиденциальности ',
                                    style: TextStyle(color: const Color(0xFFA441DC), fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(
                                    text: 'и ',
                                    style: TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                  TextSpan(
                                    text: 'Условиями использования',
                                    style: TextStyle(color: const Color(0xFFA441DC), fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String digits) {
    String text = digits;
    if (text.startsWith('7') || text.startsWith('8')) {
      text = text.substring(1);
    }
    if (text.length > 10) {
      text = text.substring(0, 10);
    }
    String res = '+7 ';
    if (text.isNotEmpty) {
      res += '(' + text.substring(0, text.length > 3 ? 3 : text.length);
      if (text.length > 3) res += ') ' + text.substring(3, text.length > 6 ? 6 : text.length);
      if (text.length > 6) res += ' ' + text.substring(6, text.length > 8 ? 8 : text.length);
      if (text.length > 8) res += ' ' + text.substring(8, text.length);
    }
    return res;
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.startsWith('7') || text.startsWith('8')) text = text.substring(1);
    if (text.length > 10) text = text.substring(0, 10);
    String res = '+7 ';
    if (text.isNotEmpty) {
      res += '(' + text.substring(0, text.length > 3 ? 3 : text.length);
      if (text.length > 3) res += ') ' + text.substring(3, text.length > 6 ? 6 : text.length);
      if (text.length > 6) res += ' ' + text.substring(6, text.length > 8 ? 8 : text.length);
      if (text.length > 8) res += ' ' + text.substring(8, text.length);
    }
    return TextEditingValue(text: res, selection: TextSelection.collapsed(offset: res.length));
  }
}


