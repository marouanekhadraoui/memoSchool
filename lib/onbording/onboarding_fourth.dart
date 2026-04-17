import 'package:flutter/material.dart';
import 'dart:math';
import 'package:momoschool/pages/home_page.dart';

class OnboardingFourth extends StatefulWidget {
  final PageController controller;

  const OnboardingFourth({super.key, required this.controller});

  @override
  State<OnboardingFourth> createState() => _OnboardingFourthState();
}

class _OnboardingFourthState extends State<OnboardingFourth>
    with TickerProviderStateMixin {
  late AnimationController _brainPulseController;
  late AnimationController _sparkController;

  @override
  void initState() {
    super.initState();

    _brainPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  
  void _startTraining() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _brainPulseController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF3F0FF),
              Color(0xFFE3DAFF),
              Color(0xFFD2C6FF),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Analyzing Cognitive Patterns...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 380,
              height: 380,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _sparkController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(380, 380),
                        painter: NeuralPainterWithSparksCurved(
                          nodesPositions: [
                            Offset(100, 80),
                            Offset(300, 100),
                            Offset(280, 300),
                            Offset(80, 300),
                          ],
                          sparkAnimation: _sparkController.value,
                        ),
                      );
                    },
                  ),
                  Center(
                    child: AnimatedBuilder(
                      animation: _brainPulseController,
                      builder: (context, child) {
                        double scale = 1 + (_brainPulseController.value * 0.08);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFF7B61FF), Color(0xFF4DA6FF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(.7),
                                  blurRadius: 30,
                                  spreadRadius: 6,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.psychology,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 100 - 30,
                    top: 80 - 30,
                    child: const BrainNode(
                      label: 'Sudoku',
                      icon: Icons.extension,
                      color: Colors.blue,
                    ),
                  ),
                  Positioned(
                    left: 300 - 30,
                    top: 100 - 30,
                    child: const BrainNode(
                      label: 'Calculates',
                      icon: Icons.calculate,
                      color: Colors.orange,
                    ),
                  ),
                  Positioned(
                    left: 280 - 30,
                    top: 300 - 30,
                    child: const BrainNode(
                      label: 'Poem Perdu',
                      icon: Icons.menu_book,
                      color: Colors.green,
                    ),
                  ),
                  Positioned(
                    left: 80 - 30,
                    top: 300 - 30,
                    child: const BrainNode(
                      label: 'Tour Algérie',
                      icon: Icons.public,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                const Text(
                  'Your Brain Network Is Ready',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Every challenge makes your mind stronger',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    backgroundColor: const Color(0xFF7B61FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '🚀 Start Training',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================
// الكلاسات الخاصة بالشاشة الرابعة ----
// ===================================

class BrainNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const BrainNode({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
          ),
        )
      ],
    );
  }
}

class NeuralPainterWithSparksCurved extends CustomPainter {
  final List<Offset> nodesPositions;
  final double sparkAnimation;

  NeuralPainterWithSparksCurved({
    required this.nodesPositions,
    required this.sparkAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final sparkPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < nodesPositions.length; i++) {
      for (int j = i + 1; j < nodesPositions.length; j++) {
        final p1 = nodesPositions[i];
        final p2 = nodesPositions[j];

        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 20);
        final path = Path()..moveTo(p1.dx, p1.dy);
        path.quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
        canvas.drawPath(path, paint);

        final t = sparkAnimation;
        final dx = (1 - t) * (1 - t) * p1.dx +
            2 * (1 - t) * t * mid.dx +
            t * t * p2.dx;
        final dy = (1 - t) * (1 - t) * p1.dy +
            2 * (1 - t) * t * mid.dy +
            t * t * p2.dy;
        canvas.drawCircle(Offset(dx, dy), 4, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NeuralPainterWithSparksCurved oldDelegate) => true;
}