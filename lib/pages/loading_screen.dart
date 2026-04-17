// lib/pages/loading_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'onboarding_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController gradientController;
  late AnimationController logoController;
  late AnimationController pulseController;
  late AnimationController rippleController;

  double progress = 0;

  final String fullText = "Memoschool";
  List<bool> visibleLetters = [];

  List<String> loadingTexts = [
    "Preparing your lessons...",
    "Loading your games...",
    "Setting up your learning space...",
    "Almost there..."
  ];

  int loadingIndex = 0;

  @override
  void initState() {
    super.initState();

    visibleLetters = List.generate(fullText.length, (_) => false);

    gradientController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    logoController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward();

    pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    rippleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();

    startTextAnimation();
    startLoading();
    startLoadingMessages();
  }

  void startTextAnimation() async {
    for (int i = 0; i < visibleLetters.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        visibleLetters[i] = true;
      });
    }
  }

  void startLoading() async {
    const totalDuration = 3;
    const interval = 50;

    Timer.periodic(const Duration(milliseconds: interval), (timer) async {
      setState(() {
        progress += interval / (totalDuration * 1000);
        if (progress > 1) progress = 1;
      });

      if (progress >= 1) {
        timer.cancel();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

        if (isFirstLaunch) {
          await prefs.setBool('first_launch', false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    });
  }

  void startLoadingMessages() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        loadingIndex = (loadingIndex + 1) % loadingTexts.length;
      });
    });
  }

  @override
  void dispose() {
    gradientController.dispose();
    logoController.dispose();
    pulseController.dispose();
    rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.white,
                  Color(0xFFF3F0FF),
                  Color(0xFFE3DAFF),
                  Color(0xFFD2C6FF),
                ],
                stops: [
                  0,
                  0.4 + gradientController.value * 0.05,
                  0.75,
                  1
                ],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: ParticlesBackground()),
               
                // Center(
                //   child: AnimatedBuilder(
                //     animation: rippleController,
                //     builder: (context, _) {
                //       return Container(
                //         width: 250,
                //         height: 250,
                //         decoration: BoxDecoration(
                //           shape: BoxShape.circle,
                //           boxShadow: [
                //             BoxShadow(
                //               color: const Color(0xFF7B61FF).withOpacity(0.2 - rippleController.value * 0.1),
                //               blurRadius: 40 + rippleController.value * 30,
                //               spreadRadius: 10 + rippleController.value * 20,
                //             ),
                //           ],
                //         ),
                //       );
                //     },
                //   ),
                // ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo 
                      FadeTransition(
                        opacity: logoController,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: logoController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: pulseController,
                            builder: (context, _) {
                              double pulse = 1 + pulseController.value * 0.03;
                              return Transform.scale(
                                scale: pulse,
                                child: Image.asset(
                                  "assets/logo.png",
                                  width: 180,
                                  height: 180,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // اسم التطبيق مع تأثير ارتداد ----
                      ShaderMask(
                        shaderCallback: (rect) {
                          return ui.Gradient.linear(
                            Offset(0, rect.height),
                            Offset(rect.width, 0),
                            const [
                              Color(0xFF7B61FF),
                              Color(0xFF4DA6FF),
                              Color(0xFFA8C8FF),
                            ],
                            const [0, .5, 1],
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(fullText.length, (i) {
                            return AnimatedSlide(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                              offset: visibleLetters[i] ? Offset.zero : const Offset(0, 2),
                              child: AnimatedOpacity(
                                opacity: visibleLetters[i] ? 1 : 0,
                                duration: const Duration(milliseconds: 400),
                                child: Transform.rotate(
                                  angle: visibleLetters[i] ? 0 : (Random().nextDouble() - 0.5) * 0.8,
                                  child: Text(
                                    fullText[i],
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                      fontFamily: "Montserrat",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      const Text(
                        "Train your brain every day",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B4EFF),
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      FancyLoader(progress: progress),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF7B61FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              loadingTexts[loadingIndex],
                              key: ValueKey(loadingIndex),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF777777),
                                letterSpacing: .4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  final Random random = Random();
  final List<Offset> particles = [];

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    for (int i = 0; i < 80; i++) {
      particles.add(Offset(random.nextDouble(), random.nextDouble()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: ParticlePainter(particles, controller.value),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF9A79FF).withOpacity(0.12);
    for (var p in particles) {
      double x = p.dx * size.width;
      double y = (p.dy * size.height + progress * 40) % size.height;
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class FancyLoader extends StatelessWidget {
  final double progress;

  const FancyLoader({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFDAD2FF),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7B61FF),
                Color(0xFF4DA6FF),
              ],
            ),
          ),
        ),
      ),
    );
  }
}