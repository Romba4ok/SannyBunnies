import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/authorization/login_page.dart';


class AuthChoicePage extends StatefulWidget {
  const AuthChoicePage({Key? key}) : super(key: key);

  @override
  State<AuthChoicePage> createState() => _AuthChoicePageState();
}

class _AuthChoicePageState extends State<AuthChoicePage> {
  int _pressed = 0;

  Future<void> _onTap(int which) async {
    setState(() => _pressed = which);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _pressed = 0);
    if (which == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage(isRegisterMode: true)));
    } else if (which == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage(isRegisterMode: false)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0xFF131010),
          child: Column(
            children: [
              Container(
                height: size.height * 0.6,
                width: size.width,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/authChoicePage/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 180,
                        width: size.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/authChoicePage/sunny.png',
                            width: size.width * 0.28,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'СОЛНЕЧНЫЕ ЗАЙКИ',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF808080), Color(0xFF303030)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 0),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _pressed == 1 ? Color(0xFFA442DC) : Colors.black,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(27),
                            onTap: () => _onTap(1),
                            onTapDown: (_) => setState(() => _pressed = 1),
                            onTapCancel: () => setState(() => _pressed = 0),
                            child: Center(
                              child: Text('Зарегистрироваться', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF808080), Color(0xFF303030)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: _pressed == 2 ? Color(0xFFA442DC) : Colors.black,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(27),
                            onTap: () => _onTap(2),
                            onTapDown: (_) => setState(() => _pressed = 2),
                            onTapCancel: () => setState(() => _pressed = 0),
                            child: Center(
                              child: Text('Войти', style: TextStyle(color: _pressed == 2 ? Colors.black : Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
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


