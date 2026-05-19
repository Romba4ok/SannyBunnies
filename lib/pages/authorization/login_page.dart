import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sannybunnies/services/login_service.dart';

class LoginPage extends StatefulWidget {
  final bool isRegisterMode;

  const LoginPage({Key? key, this.isRegisterMode = false}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool _isRegister;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7 ');
  final _confirmController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure = true;
  bool _obscure1 = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.isRegisterMode;
    for (var node in [_nameFocus, _emailFocus, _phoneFocus, _passwordFocus, _confirmFocus]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var node in [_nameFocus, _emailFocus, _phoneFocus, _passwordFocus, _confirmFocus]) {
      node.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _formKey.currentState?.reset();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final svc = LoginService.instance;

    print('_submit -> isRegister=$_isRegister email=${_emailController.text} name=${_nameController.text} phone=${_phoneController.text}');

    try {
      if (_isRegister) {
        await svc.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text,
        );
      } else {
        await svc.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isRegister ? 'Регистрация успешна' : 'Вход успешен')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseException catch (e) {
      print('_submit -> FirebaseException: ${e.code} ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
      }
    } catch (e) {
      print('_submit -> Exception: $e');
      try {
        throw e;
      } catch (err, st) {
        print('_submit -> stack: $st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildField({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    bool isObscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return FormField<String>(
      key: key,
      validator: validator,
      builder: (state) {
        BoxDecoration outerDecoration;
        if (state.hasError) {
          outerDecoration = BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12));
        } else if (focusNode.hasFocus) {
          outerDecoration = BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12));
        } else {
          outerDecoration = BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [Color(0xFF808080), Color(0xFF303030)]),
          );
        }

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
                  obscureText: isObscure,
                  keyboardType: keyboardType,
                  inputFormatters: formatters,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => state.didChange(v),
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
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(state.errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                      Text(
                        _isRegister ? 'Создайте аккаунт' : 'С возвращением!',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegister ? 'Заполните данные для регистрации' : 'Всё о вашем ребёнке — снова рядом с вами',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isRegister) ...[
                              _buildField(
                                key: const ValueKey('f_name'),
                                controller: _nameController,
                                focusNode: _nameFocus,
                                hint: 'Имя',
                                validator: (v) => (v == null || v.isEmpty) ? 'Введите имя' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildField(
                              key: _emailFieldKey,
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hint: 'Ваш Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || !v.contains('@')) ? 'Некорректный Email' : null,
                            ),
                            const SizedBox(height: 16),
                            if (_isRegister) ...[
                              _buildField(
                                key: const ValueKey('f_phone'),
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                hint: 'Ваш номер телефона',
                                keyboardType: TextInputType.phone,
                                formatters: [_PhoneFormatter()],
                                validator: (v) => (v != null && v.length < 18) ? 'Введите полный номер' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildField(
                              key: const ValueKey('f_pass'),
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hint: 'Пароль',
                              isObscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) => (v == null || v.length < 8) ? 'Минимум 8 символов' : null,
                            ),
                            SizedBox(height: _isRegister ? 16 : 0),
                            if (_isRegister) ...[
                              _buildField(
                                key: const ValueKey('f_confirm'),
                                controller: _confirmController,
                                focusNode: _confirmFocus,
                                hint: 'Подтвердите пароль',
                                isObscure: _obscure1,
                                suffix: IconButton(
                                  icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                                ),
                                validator: (v) => v != _passwordController.text ? 'Пароли не совпадают' : null,
                              ),
                            ],
                            if (!_isRegister) ...[
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  onTap: _loading
                              ? null
                              : () async {
                                  if (!(_emailFieldKey.currentState?.validate() ?? false)) {
                                    _emailFocus.requestFocus();
                                    return;
                                  }
                                  setState(() => _loading = true);
                                  try {
                                    await LoginService.instance.sendPasswordReset(_emailController.text.trim());
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Письмо для восстановления пароля отправлено на Email')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _loading = false);
                                  }
                                },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Забыли пароль?', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 1,
                                        width: 120,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: [Color(0xFF808080), Color(0xFF303030)]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: _isRegister ? 40 : 80),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA441DC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(_isRegister ? 'Создать' : 'Продолжить', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF303030), Color(0xFF808080)])))),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('или', style: TextStyle(color: Colors.white54, fontSize: 14))),
                                Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF808080), Color(0xFF303030)])))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF262626),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: _loading ? null : () async {
                                  setState(() => _loading = true);
                                  try {
                                    print('Начинаю вызов _googleSignIn.signIn()');
                                    await LoginService.instance.signInWithGoogle();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вход через Google успешен')));
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                    }
                                  } catch (e) {
                                    print('Google sign-in error: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _loading = false);
                                  }
                                },
                                icon: Image.asset('assets/images/loginPage/google.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 30)),
                                label: const Text('Продолжить с Google', style: TextStyle(color: Colors.white, fontSize: 18)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isRegister ? 'Уже есть аккаунт? ' : 'У вас нет аккаунта? ', style: const TextStyle(color: Colors.white70)),
                                GestureDetector(
                                  onTap: _toggleMode,
                                  child: Text(_isRegister ? 'Войти' : 'Создать', style: const TextStyle(color: Color(0xFFE5D1B2), fontWeight: FontWeight.bold)),
                                ),
                              ],
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            child: IconButton(
              iconSize: 32,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
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

