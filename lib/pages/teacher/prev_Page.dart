import 'package:flutter/material.dart';
import 'package:sannybunnies/pages/teacher/dashboard.dart';

class TeacherPrevPage extends StatefulWidget {
  const TeacherPrevPage({Key? key}) : super(key: key);

  @override
  State<TeacherPrevPage> createState() => _TeacherPrevPageState();
}

class _TeacherPrevPageState extends State<TeacherPrevPage> {
  
  double _dragPosition = 0.0;
  bool _isTriggered = false;

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 80.0;
    const double innerCircleSize = 64.0;
    const double paddingOffset = 8.0; 

    return Scaffold(
      backgroundColor: const Color(0xFF090707),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                'assets/images/prevPage/container_teacher.png',
                height: MediaQuery.of(context).size.height * 0.45,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.auto_awesome_mosaic,
                  size: 200,
                  color: Color(0xFFA441DC),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Откройте мир знаний',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F122E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Солнечные зайки',
                style: TextStyle(
                  color: Color(0xFFA441DC),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Редактируйте актуальные данные',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const Spacer(flex: 3),

            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  
                  final double maxDragDistance = constraints.maxWidth - innerCircleSize - (paddingOffset * 2);

                  return Container(
                    height: buttonHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151212),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Stack(
                      children: [
                        
                        const Positioned.fill(
                          child: Center(
                            child: Text(
                              'Продолжить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        
                        Positioned(
                          right: paddingOffset,
                          top: (buttonHeight - innerCircleSize) / 2,
                          child: Container(
                            width: innerCircleSize,
                            height: innerCircleSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFFA441DC),
                              size: 38,
                            ),
                          ),
                        ),

                        
                        Positioned(
                          left: paddingOffset + _dragPosition,
                          top: (buttonHeight - innerCircleSize) / 2,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              if (_isTriggered) return;
                              setState(() {
                                _dragPosition += details.delta.dx;
                                
                                _dragPosition = _dragPosition.clamp(0.0, maxDragDistance);
                              });
                            },
                            onHorizontalDragEnd: (details) async {
                              if (_isTriggered) return;

                              
                              if (_dragPosition >= maxDragDistance * 0.95) {
                                _isTriggered = true;
                                setState(() {
                                  _dragPosition = maxDragDistance; 
                                });

                                
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const TeacherDashboardPage()),
                                );
                              } else {
                                
                                while (_dragPosition > 0) {
                                  await Future.delayed(const Duration(milliseconds: 1));
                                  setState(() {
                                    _dragPosition -= 5; 
                                    if (_dragPosition < 0) _dragPosition = 0;
                                  });
                                }
                              }
                            },
                            child: Container(
                              width: innerCircleSize,
                              height: innerCircleSize,
                              decoration: const BoxDecoration(
                                color: Color(0xFFA441DC),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFA441DC),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}