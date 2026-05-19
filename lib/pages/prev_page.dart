import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_wrapper.dart';

class PrevPage extends StatefulWidget {
  const PrevPage({Key? key}) : super(key: key);

  @override
  State<PrevPage> createState() => _PrevPageState();
}

class _PrevPageState extends State<PrevPage> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSeen();
  }

  Future<void> _checkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_preview') ?? false;
    if (seen) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)));
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _setSeenAndOpenLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_preview', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper(seenPreview: true)));
  }

  void _next() {
    if (_index < 1) {
      _controller.animateToPage(_index + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _setSeenAndOpenLogin();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/prevPage/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _buildPreview(
                      context,
                      image: 'assets/images/prevPage/container1.png',
                      title: 'Будьте на связи каждый день новости, события и обратная связь от воспитателя',
                    ),
                    _buildPreview(
                      context,
                      image: 'assets/images/prevPage/container2.png',
                      title: 'С приложением вы не просто получаете информацию - вы участвуете в жизни и развитии вашего ребёнка каждый день.',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40,),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (i) => _dot(i == _index)),
                ),
              ),

              SizedBox(height: 40,),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: InkWell(
                    onTap: _next,
                    borderRadius: BorderRadius.circular(32),
                    child:Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF808080), Color(0xFF303030)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(1),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(31),
                          color: const Color(0xFF090707),
                        ),
                        child: const Center(
                          child: Text(
                            'Далее',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  ),
                ),
              ),

              SizedBox(height: 40,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: active ? 14 : 8,
      height: active ? 14 : 8,
      decoration: BoxDecoration(
        color: active ? Colors.purple : Colors.white54,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, {required String image, required String title,}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: const SizedBox()),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Image.asset(image, fit: BoxFit.contain),
        ),
        const SizedBox(height: 100),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Column(
            children: [
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}


